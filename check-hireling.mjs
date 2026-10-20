import fs from "node:fs";
import { createRequire } from "node:module";

const require = createRequire("/tmp/luatools/package.json");
const luaparse = require("luaparse");

const root = new URL("./Hireling/", import.meta.url);
const read = (name) => fs.readFileSync(new URL(name, root), "utf8");

const files = ["Core.lua", "Comms.lua", "UI.lua"];
const issues = [];
const source = {};

for (const file of files) {
  source[file] = read(file);
  try {
    luaparse.parse(source[file], { luaVersion: "5.1" });
  } catch (error) {
    issues.push(`${file} does not parse: ${error.message}`);
  }
}

const version = source["Core.lua"].match(/ns\.VERSION = "([^"]+)"/)?.[1];
const toc = read("Hireling.toc").match(/## Version: ([^\r\n]+)/)?.[1];
const camelot = read("Hireling_Camelot.toc").match(/## Version: ([^\r\n]+)/)?.[1];
const changelog = read("CHANGELOG.txt").match(/^([0-9.]+)/)?.[1];

if (!version) issues.push("Core.lua has no version");
if (toc !== version) issues.push(`Hireling.toc is ${toc}, Core.lua is ${version}`);
if (camelot !== version) issues.push(`Camelot toc is ${camelot}, Core.lua is ${version}`);
if (changelog !== version) issues.push(`CHANGELOG.txt starts at ${changelog}, Core.lua is ${version}`);
if (version && !source["Core.lua"].includes(`ns.CHANGELOG = [[${version}`)) {
  issues.push("the in-addon changelog does not start with this version");
}

if (source["UI.lua"].includes("^(%S+)")) {
  issues.push("a name is still cut at the first word");
}
if (!source["Comms.lua"].includes("ns.ShowClaim")) {
  issues.push("a claim is not wired to a popup");
}
if (!source["UI.lua"].includes("ns.SendTo(listing.owner, packet)")) {
  issues.push("a claim is not sent directly to the poster");
}
if (!source["Core.lua"].includes("function ns.PlayerName")) {
  issues.push("full-name handling is missing");
}
if (!source["UI.lua"].includes("function ns.CreateMinimapButton")) {
  issues.push("the minimap button is missing");
}
if (!source["Core.lua"].includes("function ns.Greet")) {
  issues.push("the login version line is missing");
}
if (source["Comms.lua"].includes("Clean(owner, 12)") || source["Comms.lua"].includes("Clean(parts[2], 12)")) {
  issues.push("a name field is still capped at 12 characters");
}

if (!source["UI.lua"].includes("Already taken by")) {
  issues.push("a second claim is not blocked");
}
if (!source["UI.lua"].includes("function ns.DeclineClaim")) {
  issues.push("a claim cannot be declined");
}
if (!source["Comms.lua"].includes('opcode == "N"')) {
  issues.push("a decline is not received");
}
if (!source["UI.lua"].includes("function ns.ShowDone")) {
  issues.push("marking done does not ping");
}
if (!source["UI.lua"].includes("Test claim. This is the box the poster gets.")) {
  issues.push("test mode does not show the claim box");
}

if (issues.length) {
  console.error(`Hireling check failed (${issues.length})`);
  for (const issue of issues) console.error(`- ${issue}`);
  process.exit(1);
}

console.log(`Hireling check passed. ${version}`);
