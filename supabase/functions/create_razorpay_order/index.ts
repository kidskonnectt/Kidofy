import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

const RAZORPAY_API_KEY = "rzp_live_SMOkShIYcMBuLb";
const RAZORPAY_API_SECRET = "0yeYehtFaK65OFhfZesOZQ9u";

interface CreateOrderRequest {
  user_id: string;
  amount: string; // Amount in paise
  plan_name: string;
}

interface CreateOrderResponse {
  order_id: string;
  amount: string;
  currency: string;
  status?: string;
}

const createRazorpayOrder = async (
  request: CreateOrderRequest
): Promise<CreateOrderResponse> => {
  const { amount, plan_name } = request;

  const auth = btoa(`${RAZORPAY_API_KEY}:${RAZORPAY_API_SECRET}`);

  console.log("Creating Razorpay order for plan:", plan_name, "Amount:", amount);

  const response = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: parseInt(amount),
      currency: "INR",
      receipt: `kidofy_${plan_name}_${Date.now()}`,
      notes: {
        plan_name: plan_name,
        app: "kidofy",
      },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error("Razorpay API error:", response.status, errorText);
    throw new Error(`Razorpay API error: ${response.statusText} - ${errorText}`);
  }

  const data = await response.json();
  console.log("Order created successfully:", data.id);
  return {
    order_id: data.id,
    amount: data.amount.toString(),
    currency: data.currency,
    status: data.status,
  };
};

serve(async (req: Request) => {
  // Enable CORS for all requests
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Log incoming request
    console.log("Function called with method:", req.method);
    
    const { user_id, amount, plan_name } = await req.json();
    console.log("Request data - user_id:", user_id, "plan_name:", plan_name);

    if (!user_id || !amount || !plan_name) {
      console.error("Missing required fields");
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { 
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }

    const orderData = await createRazorpayOrder({
      user_id,
      amount,
      plan_name,
    });

    return new Response(JSON.stringify(orderData), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    });
  } catch (error) {
    console.error("Error in create_razorpay_order:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({
        error: errorMessage,
        code: "ORDER_CREATION_FAILED",
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    );
  }
});
