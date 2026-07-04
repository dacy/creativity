import { NextResponse } from "next/server";
import { getProfile } from "@/lib/db";

export const runtime = "nodejs";

export async function GET() {
  return NextResponse.json({ profile: getProfile() });
}
