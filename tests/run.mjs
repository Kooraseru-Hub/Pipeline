import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const project = path.resolve(import.meta.dirname, "..");
const tool = process.env.LUAU_BIN || "luau";
const middleware = fs.readFileSync(path.join(project, "src/Pipeline/Middleware.luau"), "utf8");
const core = fs.readFileSync(path.join(project, "src/Pipeline/init.luau"), "utf8");
const runtime = fs.readFileSync(path.join(project, "tests/Runtime.spec.luau"), "utf8");

// The standalone runner isolates required modules, so bundle them into the mock engine test.
const embeddedCore = core.replace(
    'local Middleware = require(script.Middleware)',
    `local Middleware = (loadstring([==[${middleware}]==]))()`,
);

const bundledRuntime = runtime.replace(
    'local Pipeline = require("../src/Pipeline")',
    `local Pipeline = (loadstring([====[${embeddedCore}]====]))()`,
);

const directory = fs.mkdtempSync(path.join(os.tmpdir(), "pipeline-tests-"));

try {
    const generated = path.join(directory, "Runtime.spec.luau");
    fs.writeFileSync(generated, bundledRuntime);

    execFileSync(tool, ["-O2", path.join(project, "tests/Middleware.spec.luau")], { stdio: "inherit" });
    execFileSync(tool, ["-O2", generated], { stdio: "inherit" });
} finally {
    fs.rmSync(directory, { recursive: true, force: true });
}
