import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";

export const metadata: Metadata = {
  title: "Spark — AI activity ideas that learn your taste",
  description:
    "Tell it your criteria, swipe on ideas, and watch the recommendations get eerily good.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <header className="topbar">
          <Link href="/" className="brand">
            ✦ Spark
          </Link>
          <nav>
            <Link href="/">Swipe</Link>
            <Link href="/liked">Liked</Link>
            <Link href="/profile">Your taste</Link>
          </nav>
        </header>
        <main>{children}</main>
      </body>
    </html>
  );
}
