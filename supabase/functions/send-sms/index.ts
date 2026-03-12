import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

interface WebhookPayload {
  user: {
    phone: string;
  };
  sms: {
    otp: string;
  };
}

Deno.serve(async (req) => {
  try {
    const payload = await req.text();
    const headers = Object.fromEntries(req.headers);

    // Verify the request is from Supabase
    const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET") ?? "";
    const wh = new Webhook(hookSecret);
    const { user, sms } = wh.verify(payload, headers) as WebhookPayload;

    const phone = user.phone;
    const otp = sms.otp;

    console.log(`Sending OTP to ${phone}`);

    // Send via Unifonic
    const response = await fetch("https://api.unifonic.com/rest/SMS/messages", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        AppSid:    Deno.env.get("UNIFONIC_APP_SID") ?? "",
        Recipient: phone,
        Body:      `Your Century Fries verification code is: ${otp}`,
        SenderID:  Deno.env.get("UNIFONIC_SENDER_ID") ?? "",
      }),
    });

    const result = await response.json();
    console.log("Unifonic response:", JSON.stringify(result));

    if (!response.ok) {
      throw new Error(`Unifonic error: ${JSON.stringify(result)}`);
    }

    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("SMS Hook error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }
});