const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { google } = require("googleapis");
const dayjs = require("dayjs");
admin.initializeApp();
const db = admin.firestore();
// ---------------- CONFIG ----------------
const SHEET_ID = "1HNqpg6K1L5JrGHKws6C93CWCG0ygSTkOcLwyQqvQSEo";
const SHEET_NAME = "Leads for AI Emails";
// ---------------- AUTH (CLOUD IDENTITY) ----------------
const auth = new google.auth.GoogleAuth({
  scopes: [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
  ],
});
const sheets = google.sheets({ version: "v4", auth });
// ---------------- MAPPERS ----------------
// Column order: Lead ID, JHP Lead Source, First Name, Last Name, Company, Website,
// Contact Email, Contact Phone, Status, Demo Video Unique Link, Territory, Date Added, Notes
function mapRowToLead(row) {
  return {
    leadId: row[0],
    jhpLeadSource: row[1],
    firstName: row[2],
    lastName: row[3],
    company: row[4],
    website: row[5],
    contactEmail: row[6],
    contactPhone: row[7],
    status: row[8],
    demoVideoUniqueLink: row[9],
    territory: row[10],
    dateAdded: row[11] ? new Date(row[11]) : new Date(),
    notes: row[12] || "",
    // System-managed fields (not in spreadsheet, preserve existing or set defaults)
    sequenceStep: 0, // Will be set by frontend when email is sent
    updatedFromSheetAt: new Date(),
  };
}
function mapLeadToRow(lead) {
  return [
    lead.leadId || "",
    lead.jhpLeadSource || "",
    lead.firstName || "",
    lead.lastName || "",
    lead.company || "",
    lead.website || "",
    lead.contactEmail || "",
    lead.contactPhone || "",
    lead.status || "",
    lead.demoVideoUniqueLink || "",
    lead.territory || "",
    lead.dateAdded ? dayjs(lead.dateAdded.toDate()).format() : "",
    lead.notes || "",
  ];
}
// ---------------- SHEET → FIRESTORE ----------------
async function syncSheetToFirestore() {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A2:M`,
  });
  const rows = res.data.values || [];
  let created = 0;
  let updated = 0;
  for (const row of rows) {
    const lead = mapRowToLead(row);
    const ref = db.collection("leads").doc(lead.leadId);
    const snap = await ref.get();
    if (!snap.exists) {
      await ref.set(lead);
      created++;
    } else {
      const firestoreUpdated = snap.data().updatedFromSheetAt?.toDate();
      if (!firestoreUpdated || lead.updatedFromSheetAt > firestoreUpdated) {
        // Preserve system-managed fields that aren't in the spreadsheet
        const existing = snap.data();
        const mergedLead = {
          ...lead,
          // Preserve system fields if they exist
          sequenceStep: existing.sequenceStep !== undefined ? existing.sequenceStep : lead.sequenceStep,
          assignedTo: existing.assignedTo || null,
          nextFollowupAt: existing.nextFollowupAt || null,
          lastContactedAt: existing.lastContactedAt || null,
        };
        await ref.set(mergedLead, { merge: true });
        updated++;
      }
    }
  }
  return { created, updated };
}
// ---------------- FIRESTORE → SHEET ----------------
async function syncFirestoreToSheet() {
  // First, read existing sheet data to preserve all read-only fields
  // Only Status can be written from Firestore - all other fields come from sheet
  const existingSheet = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A2:M`,
  });
  const existingRows = existingSheet.data.values || [];
  
  // Create a map of leadId -> existing row data from sheet
  // Column order: Lead ID, JHP Lead Source, First Name, Last Name, Company, Website,
  // Contact Email, Contact Phone, Status, Demo Video Unique Link, Territory, Date Added, Notes
  const existingRowMap = new Map();
  existingRows.forEach(row => {
    if (row[0]) { // leadId is in column 0
      existingRowMap.set(row[0], row);
    }
  });
  
  // Get all leads from Firestore and map to rows
  const snapshot = await db.collection("leads").get();
  const rows = [];
  snapshot.forEach((doc) => {
    const lead = doc.data();
    const existingRow = existingRowMap.get(lead.leadId);
    
    if (existingRow) {
      // Lead exists in sheet - preserve all fields from sheet except Status
      const row = [...existingRow]; // Copy existing row
      row[8] = lead.status || ""; // Column 8 = Status (only field we write from Firestore)
      rows.push(row);
    } else {
      // New lead not in sheet - create row from Firestore (this shouldn't normally happen)
      const row = mapLeadToRow(lead);
      rows.push(row);
    }
  });
  
  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A2:M`,
    valueInputOption: "RAW",
    requestBody: { values: rows },
  });
  return rows.length;
}
// ---------------- MANUAL SYNC ----------------
exports.manualSheetSync = onRequest(async (req, res) => {
  try {
    const client = await auth.getClient();
    const projectId = await auth.getProjectId();

    console.log("✅ AUTH PROJECT:", projectId);
    console.log("✅ AUTH CLIENT EMAIL:", client.email || "NO EMAIL FOUND");

    const sheetResult = await syncSheetToFirestore();
    const count = await syncFirestoreToSheet();

    res.json({
      success: true,
      sheetToFirestore: sheetResult,
      firestoreToSheetCount: count
    });
  } catch (err) {
    console.error("🔥 SYNC ERROR:", err);
    res.status(500).json({ error: err.message });
  }
});
// ---------------- SEND EMAIL ----------------
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const sgMail = require("@sendgrid/mail");

const SENDGRID_API_KEY = defineSecret("SENDGRID_API_KEY");

// Map Firebase UID -> allowed sender identity
// (You can move this to Firestore config later.)
const SENDER_MAP = {
  // uid: { email, name }
  "zuFv95G6LpRDW686BHLHdrp77873": { email: "ben@jobhubpro.io", name: "Benjamin Hart" },
  "2CUUbRRLPthbU2NjjD3K5EpXmag2": { email: "dawson@jobhubpro.io", name: "Dawson Racek" },
};

exports.sendOutreachEmail = onCall(
  { secrets: [SENDGRID_API_KEY] },
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "Login required.");

    const uid = req.auth.uid;
    const sender = SENDER_MAP[uid];
    if (!sender) throw new HttpsError("permission-denied", "Sender not allowed for this user.");

    const {
      leadId,                 // Firestore doc id or Lead ID string
      toEmail,
      subject,
      html,                   // email body HTML
      text,                   // optional fallback
      testMode,               // boolean
    } = req.data || {};

    if (!leadId || !toEmail || !subject || !html) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    // Load lead to validate ownership + status
    const leadRef = db.collection("leads").doc(String(leadId));
    const leadSnap = await leadRef.get();
    if (!leadSnap.exists) throw new HttpsError("not-found", "Lead not found.");

    const lead = leadSnap.data() || {};

    // Enforce "my leads only" via JHP Lead Source
    if (lead.jhpLeadSource !== sender.name) {
      throw new HttpsError("permission-denied", "You can only send emails for your own leads.");
    }

    // Only allow sending for Not Contacted queue (for now)
    if (lead.status !== "Not Contacted") {
      throw new HttpsError("failed-precondition", "Lead is not in Not Contacted status.");
    }

    const actualTo = testMode ? sender.email : toEmail;

    sgMail.setApiKey(SENDGRID_API_KEY.value());

    const msg = {
      to: actualTo,
      from: { email: sender.email, name: sender.name },
      replyTo: { email: sender.email, name: sender.name },
      subject,
      html,
      ...(text ? { text } : {}),
    };

    try {
      await sgMail.send(msg);

      // Update lead state (Firestore-owned truth)
      await leadRef.update({
        status: "Email 1 Sent",
        lastContactedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSentByUid: uid,
        lastSentFrom: sender.email,
        lastSentTo: actualTo,
        lastSentSubject: subject,
      });

      return { ok: true, sentTo: actualTo };
    } catch (err) {
      console.error("SendGrid send error:", err);
      throw new HttpsError("internal", "Failed to send email.");
    }
  }
);




