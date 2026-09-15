import type { ReactElement } from "react";
import { SiteHeader } from "./SiteHeader";
import { SiteFooter } from "./SiteFooter";

/**
 * Minimal markdown-ish renderer for legal pages.
 * Supports: # H1 (blue), ## H2, ### H3, --- hr, * list, **bold**, [text](url), blank-line paragraphs.
 */
function renderInline(text: string, keyBase: string) {
  // links first
  const parts: (string | ReactElement)[] = [];
  const linkRe = /\[([^\]]+)\]\(([^)]+)\)/g;
  let last = 0;
  let m: RegExpExecArray | null;
  let i = 0;
  while ((m = linkRe.exec(text)) !== null) {
    if (m.index > last) parts.push(text.slice(last, m.index));
    parts.push(
      <a key={`${keyBase}-l${i++}`} href={m[2]} className="text-[#1e3a8a] underline hover:text-orange">
        {m[1]}
      </a>,
    );
    last = m.index + m[0].length;
  }
  if (last < text.length) parts.push(text.slice(last));

  // bold within string parts
  return parts.flatMap((p, idx) => {
    if (typeof p !== "string") return [p];
    const out: (string | ReactElement)[] = [];
    const re = /\*\*([^*]+)\*\*/g;
    let l = 0;
    let mm: RegExpExecArray | null;
    let j = 0;
    while ((mm = re.exec(p)) !== null) {
      if (mm.index > l) out.push(p.slice(l, mm.index));
      out.push(
        <strong key={`${keyBase}-b${idx}-${j++}`} className="font-bold text-black">
          {mm[1]}
        </strong>,
      );
      l = mm.index + mm[0].length;
    }
    if (l < p.length) out.push(p.slice(l));
    return out;
  });
}

function renderMarkdown(md: string) {
  const lines = md.replace(/\r\n/g, "\n").split("\n");
  const nodes: ReactElement[] = [];
  let i = 0;
  let key = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (!line.trim()) {
      i++;
      continue;
    }
    if (line.startsWith("# ")) {
      nodes.push(
        <h1 key={key++} className="mt-10 font-display text-3xl font-black text-[#1e3a8a] sm:text-4xl">
          {renderInline(line.slice(2), `h1-${key}`)}
        </h1>,
      );
      i++;
    } else if (line.startsWith("## ")) {
      nodes.push(
        <h2 key={key++} className="mt-8 text-xl font-bold text-black sm:text-2xl">
          {renderInline(line.slice(3), `h2-${key}`)}
        </h2>,
      );
      i++;
    } else if (line.startsWith("### ")) {
      nodes.push(
        <h3 key={key++} className="mt-6 text-lg font-bold text-black">
          {renderInline(line.slice(4), `h3-${key}`)}
        </h3>,
      );
      i++;
    } else if (/^---+\s*$/.test(line)) {
      nodes.push(<hr key={key++} className="my-6 border-border" />);
      i++;
    } else if (line.startsWith("* ")) {
      const items: string[] = [];
      while (i < lines.length && lines[i].startsWith("* ")) {
        items.push(lines[i].slice(2));
        i++;
      }
      nodes.push(
        <ul key={key++} className="my-3 list-disc space-y-1 pl-6 text-black">
          {items.map((it, idx) => (
            <li key={idx}>{renderInline(it, `li-${key}-${idx}`)}</li>
          ))}
        </ul>,
      );
    } else {
      // paragraph: collect until blank line
      const buf: string[] = [line];
      i++;
      while (
        i < lines.length &&
        lines[i].trim() &&
        !lines[i].startsWith("#") &&
        !lines[i].startsWith("* ") &&
        !/^---+\s*$/.test(lines[i])
      ) {
        buf.push(lines[i]);
        i++;
      }
      nodes.push(
        <p key={key++} className="my-3 leading-relaxed text-black">
          {renderInline(buf.join(" "), `p-${key}`)}
        </p>,
      );
    }
  }
  return nodes;
}

export function LegalDoc({ markdown }: { markdown: string }) {
  return (
    <div className="min-h-screen bg-background">
      <SiteHeader />
      <main className="mx-auto max-w-3xl px-4 py-12 sm:px-6 lg:px-8">{renderMarkdown(markdown)}</main>
      <SiteFooter />
    </div>
  );
}
