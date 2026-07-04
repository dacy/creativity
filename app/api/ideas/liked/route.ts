import { NextResponse } from "next/server";
import { getIdeasByStatus } from "@/lib/db";

export const runtime = "nodejs";

export async function GET() {
  return NextResponse.json({ ideas: getIdeasByStatus("liked", 200) });
}
