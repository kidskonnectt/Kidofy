import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

const RAZORPAY_API_SECRET = "0yeYehtFaK65OFhfZesOZQ9u";

interface VerifyPaymentRequest {
  payment_id: string;
  order_id: string;
  signature: string;
}

const verifyRazorpaySignature = async (
  orderId: string,
  paymentId: string,
  signature: string
): Promise<boolean> => {
  const message = `${orderId}|${paymentId}`;
  const encodedSecret = new TextEncoder().encode(RAZORPAY_API_SECRET);
  const messageBytes = new TextEncoder().encode(message);

  // Create HMAC-SHA256 using Web Crypto API
  const key = await crypto.subtle.importKey(
    "raw",
    encodedSecret,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  
  const signatureBytes = await crypto.subtle.sign("HMAC", key, messageBytes);
  const generatedSignature = Array.from(new Uint8Array(signatureBytes))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return generatedSignature === signature;
};

serve(async (req: Request) => {
  // Enable CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Content-Type",
      },
    });
  }

  try {
    const { payment_id, order_id, signature } = await req.json();

    if (!payment_id || !order_id || !signature) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Access-Control-Allow-Origin": "*" } }
      );
    }

    const isValid = await verifyRazorpaySignature(order_id, payment_id, signature);

    return new Response(
      JSON.stringify({
        success: isValid,
        message: isValid ? "Payment verified successfully" : "Invalid signature",
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("Error verifying payment:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      { status: 500, headers: { "Access-Control-Allow-Origin": "*" } }
    );
  }
});
