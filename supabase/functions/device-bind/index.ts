import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface BindDeviceRequest {
  device_id: string;
  api_key: string;
  project_id: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseKey) {
      throw new Error("Missing environment variables");
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: {
        Authorization: `Bearer ${token}`,
        APIKey: supabaseKey,
      },
    });

    if (!userResponse.ok) {
      return new Response(
        JSON.stringify({ error: "Invalid authentication" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const user = await userResponse.json();
    const { device_id, api_key, project_id }: BindDeviceRequest = await req.json();

    if (!device_id || !api_key || !project_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const verifyResponse = await fetch(
      `${supabaseUrl}/rest/v1/devices?api_key=eq.${api_key}&device_id=eq.${device_id}&select=*`,
      {
        headers: {
          Authorization: `Bearer ${supabaseKey}`,
          APIKey: supabaseKey,
        },
      }
    );

    const devices = await verifyResponse.json();

    if (!devices || devices.length === 0) {
      return new Response(
        JSON.stringify({ error: "Invalid device ID or API key" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const device = devices[0];

    if (device.user_id && device.user_id !== user.id) {
      return new Response(
        JSON.stringify({ error: "Device already bound to another user" }),
        {
          status: 409,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const updateResponse = await fetch(
      `${supabaseUrl}/rest/v1/devices?device_id=eq.${device_id}`,
      {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${supabaseKey}`,
          APIKey: supabaseKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          user_id: user.id,
          project_id: project_id,
          is_registered: true,
          first_connected_at: device.first_connected_at || new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }),
      }
    );

    if (!updateResponse.ok) {
      throw new Error("Failed to bind device");
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Device successfully bound to your account",
        device_id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});