import { createClient } from "jsr:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// ── 위험도 계산 ────────────────────────────────────────────────────────────────
function computeRisk(waterTemp: number, ph: number, totalP: number, dissolvedO2: number) {
  const conditions: string[] = [];
  const reasons: string[] = [];

  if (waterTemp >= 25.0) { conditions.push("temp"); reasons.push(`수온 ${waterTemp.toFixed(1)}°C ≥ 25°C`); }
  if (totalP >= 0.05)    { conditions.push("phosphorus"); reasons.push(`총인 ${totalP.toFixed(3)} mg/L ≥ 0.05`); }
  if (dissolvedO2 <= 4.0){ conditions.push("do"); reasons.push(`용존산소 ${dissolvedO2.toFixed(1)} mg/L ≤ 4`); }
  if (ph >= 9.0)         { conditions.push("ph"); reasons.push(`pH ${ph.toFixed(1)} ≥ 9.0`); }

  const level = conditions.includes("temp") && conditions.includes("phosphorus")
    ? "red" : conditions.length > 0 ? "yellow" : "green";
  return { level, reason: reasons.join(" | ") || "모든 지표 정상" };
}

// ── 거리 계산 ─────────────────────────────────────────────────────────────────
function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2)**2 +
    Math.cos(lat1*Math.PI/180) * Math.cos(lat2*Math.PI/180) * Math.sin(dLng/2)**2;
  return R * 2 * Math.asin(Math.sqrt(a));
}

// ── 더미 위험도 (실 데이터 연동 전) ──────────────────────────────────────────
function dummyRisk(stationId: string) {
  const seed = stationId.charCodeAt(0) + stationId.charCodeAt(1);
  return computeRisk(22 + (seed % 7), 7.5 + (seed % 20) / 10,
    0.02 + (seed % 8) / 100, 3.5 + (seed % 5));
}

// ── Kakao 응답 빌더 ───────────────────────────────────────────────────────────
function simple(text: string, quickReplies?: { label: string; messageText: string }[]) {
  return {
    version: "2.0",
    template: {
      outputs: [{ simpleText: { text } }],
      ...(quickReplies ? { quickReplies: quickReplies.map(q => ({
        label: q.label, action: "message", messageText: q.messageText
      })) } : {}),
    },
  };
}

// ── 핸들러 ────────────────────────────────────────────────────────────────────
async function handleStart(kakaoId: string) {
  await supabase.from("reg_state").upsert({ kakao_id: kakaoId, step: "awaiting_location" });
  return simple(
    "안녕하세요! 🌊 녹조 알림 서비스입니다.\n\n양식장 주소(또는 동/읍 이름)를 입력해 주세요.\n예) 인천시 남동구 논현동",
    [{ label: "취소", messageText: "취소" }],
  );
}

async function handleLocationInput(kakaoId: string, utterance: string) {
  const address = utterance.trim();
  // 실제 운영 시 카카오 주소 API로 좌표 변환 — 지금은 인천 기본값
  const lat = 37.41, lng = 126.72;
  await supabase.from("reg_state").upsert({
    kakao_id: kakaoId, step: "awaiting_phone", lat, lng, address,
  });
  return simple(
    `📍 위치 확인: ${address}\n\n알림 받을 전화번호를 입력해 주세요.\n예) 010-1234-5678`,
  );
}

async function handlePhoneInput(kakaoId: string, utterance: string) {
  const phone = utterance.replace(/[^0-9]/g, "");
  if (!/^010\d{8}$/.test(phone)) {
    return simple("📵 전화번호 형식이 올바르지 않습니다.\n010-XXXX-XXXX 형식으로 다시 입력해 주세요.");
  }
  const { data: state } = await supabase.from("reg_state")
    .select("*").eq("kakao_id", kakaoId).single();
  if (!state || state.step !== "awaiting_phone") {
    return simple("처음부터 다시 시작해 주세요.", [{ label: "등록", messageText: "등록" }]);
  }
  await supabase.from("kakao_users").upsert({
    kakao_id: kakaoId, phone, lat: state.lat, lng: state.lng,
    address: state.address, active: true,
  });
  await supabase.from("reg_state").delete().eq("kakao_id", kakaoId);
  return simple(
    `✅ 등록 완료!\n\n📍 위치: ${state.address}\n📱 전화번호: ${phone.slice(0,3)}-${phone.slice(3,7)}-${phone.slice(7)}\n\n위험 수준 상승 시 즉시 문자로 알려드릴게요.`,
    [{ label: "상태확인", messageText: "상태확인" }, { label: "알림끄기", messageText: "알림끄기" }],
  );
}

async function handleStatus(kakaoId: string) {
  const { data: user } = await supabase.from("kakao_users")
    .select("*").eq("kakao_id", kakaoId).eq("active", true).single();
  if (!user) return simple("등록된 양식장이 없습니다.", [{ label: "등록", messageText: "등록" }]);

  const { data: stations } = await supabase.from("stations").select("*");
  if (!stations?.length) return simple("측정소 데이터가 없습니다.");

  const closest = stations.reduce((a, b) =>
    haversineKm(user.lat, user.lng, a.lat, a.lng) <
    haversineKm(user.lat, user.lng, b.lat, b.lng) ? a : b);
  const dist = haversineKm(user.lat, user.lng, closest.lat, closest.lng);
  const { level, reason } = dummyRisk(closest.id);
  const emoji = { red: "🔴", yellow: "🟡", green: "🟢" }[level] ?? "⚪";
  const label = { red: "위험", yellow: "주의", green: "정상" }[level] ?? "-";

  return simple(
    `${emoji} 현재 상태: ${label}\n\n📍 내 위치: ${user.address}\n📡 인근 측정소: ${closest.name} (${dist.toFixed(1)}km)\n⚠️ ${reason}`,
    [{ label: "등록 수정", messageText: "등록" }, { label: "알림끄기", messageText: "알림끄기" }],
  );
}

async function handleDeactivate(kakaoId: string) {
  await supabase.from("kakao_users").update({ active: false }).eq("kakao_id", kakaoId);
  return simple("알림이 비활성화됐습니다.\n다시 받으시려면 '등록'을 눌러주세요.",
    [{ label: "등록", messageText: "등록" }]);
}

// ── 메인 ─────────────────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("ok");

  const body = await req.json();
  const utterance = body?.userRequest?.utterance?.trim() ?? "";
  const kakaoId   = body?.userRequest?.user?.id ?? "unknown";

  const { data: state } = await supabase.from("reg_state")
    .select("*").eq("kakao_id", kakaoId).single();

  let resp;

  if (["등록","시작","시작하기","재등록"].includes(utterance)) {
    resp = await handleStart(kakaoId);
  } else if (["상태확인","현재상태","확인"].includes(utterance)) {
    resp = await handleStatus(kakaoId);
  } else if (["알림끄기","취소","구독취소"].includes(utterance)) {
    resp = await handleDeactivate(kakaoId);
  } else if (state?.step === "awaiting_location") {
    resp = await handleLocationInput(kakaoId, utterance);
  } else if (state?.step === "awaiting_phone") {
    resp = await handlePhoneInput(kakaoId, utterance);
  } else {
    resp = simple("안녕하세요! 녹조 알림 서비스입니다. 🌊",
      [{ label: "등록", messageText: "등록" }, { label: "상태확인", messageText: "상태확인" }]);
  }

  return new Response(JSON.stringify(resp), {
    headers: { "Content-Type": "application/json" },
  });
});
