import { createClient } from "jsr:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const SOLAPI_KEY    = Deno.env.get("SOLAPI_API_KEY")!;
const SOLAPI_SECRET = Deno.env.get("SOLAPI_API_SECRET")!;
const SOLAPI_SENDER = Deno.env.get("SOLAPI_SENDER")!;
const RADIUS_KM     = Number(Deno.env.get("ALERT_RADIUS_KM") ?? "30");
const MIN_LEVEL     = Deno.env.get("ALERT_MIN_LEVEL") ?? "yellow";

const LEVEL_ORDER: Record<string, number> = { green: 0, yellow: 1, red: 2 };

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2)**2 +
    Math.cos(lat1*Math.PI/180) * Math.cos(lat2*Math.PI/180) * Math.sin(dLng/2)**2;
  return R * 2 * Math.asin(Math.sqrt(a));
}

function computeRisk(waterTemp: number, ph: number, totalP: number, dissolvedO2: number) {
  const c: string[] = [], r: string[] = [];
  if (waterTemp >= 25) { c.push("temp"); r.push(`수온 ${waterTemp.toFixed(1)}°C`); }
  if (totalP >= 0.05)  { c.push("p");    r.push(`총인 ${totalP.toFixed(3)}mg/L`); }
  if (dissolvedO2 <= 4){ c.push("do");   r.push(`용존산소 ${dissolvedO2.toFixed(1)}mg/L`); }
  if (ph >= 9.0)       { c.push("ph");   r.push(`pH ${ph.toFixed(1)}`); }
  const level = c.includes("temp") && c.includes("p") ? "red"
              : c.length > 0 ? "yellow" : "green";
  return { level, reason: r.join(" | ") || "정상" };
}

function dummyRisk(stationId: string) {
  const s = stationId.charCodeAt(0) + stationId.charCodeAt(stationId.length - 1);
  return computeRisk(22 + (s % 8), 7.5 + (s % 18) / 10, 0.02 + (s % 9) / 100, 3.0 + (s % 6));
}

async function sendSms(to: string, text: string) {
  const date = new Date().toISOString().replace(/\.\d+Z$/, "Z");
  const salt = crypto.randomUUID().replace(/-/g, "");
  const data = date + salt;
  const key  = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(SOLAPI_SECRET),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig  = Array.from(new Uint8Array(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(data))))
    .map(b => b.toString(16).padStart(2,"0")).join("");

  const r = await fetch("https://api.solapi.com/messages/v4/send", {
    method: "POST",
    headers: {
      Authorization: `HMAC-SHA256 apiKey=${SOLAPI_KEY}, date=${date}, salt=${salt}, signature=${sig}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: { to: to.replace(/-/g,""), from: SOLAPI_SENDER, text, type: "SMS" },
    }),
  });
  return r.ok;
}

function buildText(level: string, stationName: string, reason: string, distKm: number) {
  const emoji = { red: "🔴", yellow: "🟡" }[level] ?? "🟢";
  const label = { red: "위험", yellow: "주의" }[level] ?? "정상";
  return `${emoji} [녹조 ${label} 알림]\n인근 측정소: ${stationName} (${distKm.toFixed(1)}km)\n원인: ${reason}\n양식장 관리에 주의해 주세요.\n— 부영양화 예보 서비스`;
}

Deno.serve(async () => {
  const { data: users } = await supabase.from("kakao_users")
    .select("*").eq("active", true);
  const { data: stations } = await supabase.from("stations").select("*");

  if (!users?.length || !stations?.length) {
    return new Response(JSON.stringify({ sent: 0 }), { headers: { "Content-Type": "application/json" } });
  }

  // 측정소별 위험도 계산
  const risks = Object.fromEntries(
    stations.map(s => [s.id, { ...dummyRisk(s.id), station: s }])
  );

  let sent = 0;
  for (const user of users) {
    // 반경 내 가장 위험한 측정소
    const candidates = stations
      .map(s => ({ s, dist: haversineKm(user.lat, user.lng, s.lat, s.lng), ...risks[s.id] }))
      .filter(c => c.dist <= RADIUS_KM)
      .sort((a, b) => (LEVEL_ORDER[b.level] - LEVEL_ORDER[a.level]) || (a.dist - b.dist));

    if (!candidates.length) continue;
    const best = candidates[0];
    if ((LEVEL_ORDER[best.level] ?? 0) < (LEVEL_ORDER[MIN_LEVEL] ?? 1)) continue;

    // 오늘 이미 보낸 적 있으면 스킵
    const today = new Date().toISOString().slice(0, 10);
    const { data: existing } = await supabase.from("alert_log")
      .select("id").eq("kakao_id", user.kakao_id).eq("station_id", best.s.id)
      .gte("sent_at", today).limit(1);
    if (existing?.length) continue;

    const text = buildText(best.level, best.s.name, best.reason, best.dist);
    const ok   = await sendSms(user.phone, text);
    if (ok) {
      await supabase.from("alert_log").insert({
        kakao_id: user.kakao_id, station_id: best.s.id, level: best.level, message: text,
      });
      sent++;
    }
  }

  return new Response(JSON.stringify({ sent, total: users.length }),
    { headers: { "Content-Type": "application/json" } });
});
