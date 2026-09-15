// @lovable.dev/vite-tanstack-config already includes the following — do NOT add them manually
// or the app will break with duplicate plugins:
//   - tanstackStart, viteReact, tailwindcss, tsConfigPaths, nitro (build-only using cloudflare as a default target),
//     componentTagger (dev-only), VITE_* env injection, @ path alias, React/TanStack dedupe,
//     error logger plugins, and sandbox detection (port/host/strictPort).
// You can pass additional config via defineConfig({ vite: { ... }, etc... }) if needed.
import { defineConfig } from "@lovable.dev/vite-tanstack-config";

export default defineConfig({
  // IMPORTANT: without an explicit `nitro` option here, the Lovable config
  // only runs the nitro deploy plugin when it detects a Lovable sandbox
  // (isSandbox === true). A normal `vite build` on Vercel/GitHub Actions is
  // NOT a Lovable sandbox, so nitro was silently skipped there, no
  // Vercel-compatible server output was produced, and every request came
  // back as 404 NOT_FOUND. Setting `nitro` explicitly forces the plugin to
  // run on every build (Vercel included) and targets Vercel's Build Output
  // API (outputs to `.vercel/output`, which Vercel deploys natively).
  // Note: this is overridden back to `cloudflare-module` automatically when
  // building inside an actual Lovable sandbox, so local Lovable previews
  // are unaffected.
  nitro: {
    preset: process.env.VERCEL ? "vercel" : "node-server",
  },
  tanstackStart: {
    // Redirect TanStack Start's bundled server entry to src/server.ts (our SSR error wrapper).
    // nitro/vite builds from this
    server: { entry: "src/server" },
  },
});
