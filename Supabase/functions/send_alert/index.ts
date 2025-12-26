// Sanctuary Edge Function: send_alert
// Receives user_id, latitude, longitude, message
// Looks up trusted contacts and sends SMS via Twilio


import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js";

serve(async (req) => {
  try {
    const { user_id, latitude, longitude, message } = await req.json();
    const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
    const TWILIO_SID = Deno.env.get("TWILIO_SID");
    const TWILIO_TOKEN = Deno.env.get("TWILIO_TOKEN");
    const TWILIO_FROM_NUMBER = Deno.env.get("TWILIO_FROM_NUMBER");

    // Get trusted contacts with phone numbers
    const { data: contacts, error } = await supabase
      .from("contact_relations")
      .select("trusted_contact_id, profiles:trusted_contact_id(phone_number)")
      .eq("user_id", user_id)
      .eq("is_active", true)
      .eq("can_receive_alerts", true);

    if (error) throw error;
    if (!contacts || contacts.length === 0) {
      return new Response(JSON.stringify({ success: false, error: "No trusted contacts found" }), { status: 404 });
    }

    async function sendSMS(to, body) {
      const url = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_SID}/Messages.json`;
      const params = new URLSearchParams({
        From: TWILIO_FROM_NUMBER,
        To: to,
        Body: body,
      });
      const resp = await fetch(url, {
        method: "POST",
        headers: {
          Authorization: "Basic " + btoa(`${TWILIO_SID}:${TWILIO_TOKEN}`),
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: params,
      });
      if (!resp.ok) {
        const error = await resp.text();
        throw new Error(`Twilio error: ${error}`);
      }
    }

    // Send SMS to each contact
    for (const contact of contacts) {
      const phone = contact.profiles?.phone_number;
      if (!phone) continue;
      await sendSMS(
        phone,
        `${message}\nLocation: https://maps.apple.com/?ll=${latitude},${longitude}`
      );
    }

    return new Response(JSON.stringify({ success: true }));
  } catch (e) {
    return new Response(JSON.stringify({ success: false, error: e.message }), { status: 500 });
  }
});
