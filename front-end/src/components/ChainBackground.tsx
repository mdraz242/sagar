import { useEffect, useRef } from "react";

/**
 * Dense animated chain/web background.
 * Particles always drift continuously, connected by chain links.
 * When mouse approaches, particles repel strongly (chain "parts").
 * Brand colors: blue #003399 + orange #FF6600.
 */
export function ChainBackground() {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d")!;
    let raf = 0;
    const DPR = Math.min(window.devicePixelRatio || 1, 2);

    type P = {
      x: number; y: number; vx: number; vy: number;
      baseVx: number; baseVy: number;
      color: 0 | 1; // 0 blue, 1 orange
    };
    let particles: P[] = [];
    const mouse = { x: -9999, y: -9999, active: false };

    const resize = () => {
      const w = (canvas.width = canvas.offsetWidth * DPR);
      const h = (canvas.height = canvas.offsetHeight * DPR);
      // even denser chain web
      const count = Math.min(320, Math.floor((w * h) / (9000 * DPR)));
      particles = Array.from({ length: count }, (_, i) => {
        // primary drift left -> right with a gentle vertical sway
        const sx = (0.45 + Math.random() * 0.55) * DPR;
        const sy = (Math.random() - 0.5) * 0.25 * DPR;
        return {
          x: Math.random() * w,
          y: Math.random() * h,
          vx: sx,
          vy: sy,
          baseVx: sx,
          baseVy: sy,
          color: (i % 3 === 0 ? 1 : 0) as 0 | 1,
        };
      });
    };
    resize();
    window.addEventListener("resize", resize);

    const onMove = (e: MouseEvent) => {
      const r = canvas.getBoundingClientRect();
      mouse.x = (e.clientX - r.left) * DPR;
      mouse.y = (e.clientY - r.top) * DPR;
      mouse.active = true;
    };
    const onLeave = () => (mouse.active = false);
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseleave", onLeave);

    const REPEL = 160 * DPR;
    const LINK = 120 * DPR;

    const tick = () => {
      const w = canvas.width;
      const h = canvas.height;
      ctx.clearRect(0, 0, w, h);

      for (const p of particles) {
        // ease back toward base velocity so particles keep drifting
        p.vx += (p.baseVx - p.vx) * 0.02;
        p.vy += (p.baseVy - p.vy) * 0.02;

        if (mouse.active) {
          const dx = p.x - mouse.x;
          const dy = p.y - mouse.y;
          const d = Math.hypot(dx, dy);
          if (d < REPEL && d > 0.1) {
            const force = (1 - d / REPEL) * 5;
            p.vx += (dx / d) * force;
            p.vy += (dy / d) * force;
          }
        }

        p.x += p.vx;
        p.y += p.vy;

        // wrap around edges so motion never stops
        if (p.x < -10) p.x = w + 10;
        if (p.x > w + 10) p.x = -10;
        if (p.y < -10) p.y = h + 10;
        if (p.y > h + 10) p.y = -10;
      }

      // links (chain) — dense
      ctx.lineWidth = 1 * DPR;
      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const a = particles[i];
          const b = particles[j];
          const dx = a.x - b.x;
          const dy = a.y - b.y;
          const d = Math.hypot(dx, dy);
          if (d < LINK) {
            const alpha = (1 - d / LINK) * 0.5;
            // gradient between blue & orange depending on endpoints
            if (a.color === 0 && b.color === 0) {
              ctx.strokeStyle = `rgba(0, 51, 153, ${alpha})`;
            } else if (a.color === 1 && b.color === 1) {
              ctx.strokeStyle = `rgba(255, 102, 0, ${alpha})`;
            } else {
              ctx.strokeStyle = `rgba(120, 80, 180, ${alpha * 0.9})`;
            }
            ctx.beginPath();
            ctx.moveTo(a.x, a.y);
            ctx.lineTo(b.x, b.y);
            ctx.stroke();
          }
        }
      }

      // nodes
      for (const p of particles) {
        ctx.fillStyle = p.color === 0
          ? "rgba(0, 51, 153, 0.75)"
          : "rgba(255, 102, 0, 0.85)";
        ctx.beginPath();
        ctx.arc(p.x, p.y, 2.2 * DPR, 0, Math.PI * 2);
        ctx.fill();
      }

      raf = requestAnimationFrame(tick);
    };
    tick();

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseleave", onLeave);
    };
  }, []);

  return (
    <canvas
      ref={ref}
      aria-hidden
      className="pointer-events-none absolute inset-0 h-full w-full"
    />
  );
}
