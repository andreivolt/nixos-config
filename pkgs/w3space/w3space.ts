#!/usr/bin/env -S deno run --allow-read --allow-write --allow-net --allow-env --allow-run --allow-sys --allow-ffi --ext ts
import { Command } from "https://deno.land/x/cliffy@v0.25.7/command/mod.ts";
import { create } from 'npm:@web3-storage/w3up-client';
import { contentType } from "https://deno.land/std/media_types/mod.ts";
import { readAll } from "https://deno.land/std/io/mod.ts";
import { extname, basename } from "https://deno.land/std/path/mod.ts";
import { open } from "https://deno.land/x/opener@v1.0.1/mod.ts";
import * as clippy from "https://deno.land/x/clippy/mod.ts";

async function getMimeTypeFromFileCommand(filePath: string): Promise<string> {
  const process = Deno.run({
    cmd: ["file", "--mime-type", "-b", filePath],
    stdout: "piped",
  });
  const output = await process.output();
  const mimeType = new TextDecoder().decode(output).trim();
  process.close();
  return mimeType || "application/octet-stream";
}

async function setupClient() {
  const client = await create();
  const EMAIL = Deno.env.get("EMAIL");
  if (!EMAIL) {
    console.error("Error: EMAIL environment variable is not set.");
    Deno.exit(1);
  }
  const proofs = await client.proofs();
  if (proofs.length === 0) {
    await client.login(EMAIL);
    console.log("Check your email for the confirmation link and click it.");
    await new Promise(resolve => setTimeout(resolve, 30000));
  }
  const spaces = await client.spaces();
  if (spaces.length === 0) {
    console.error("No spaces available. Please create a space in your web3.storage account.");
    Deno.exit(1);
  }
  const space = spaces[0];
  await client.setCurrentSpace(space.did());
  return client;
}

async function main() {
  await new Command()
    .name(basename(Deno.mainModule))
    .description("Upload files to web3.storage. Supports file paths or stdin input.")
    .usage("[file_path] | <stdin>")
    .option("-f, --filename <filename:string>", "Set filename")
    .option("-c, --clipboard", "Copy to clipboard")
    .option("-o, --open", "Open URL in browser")
    .arguments("[file_path:string]")
    .action(async (options, filePath) => {
      let fileName: string;
      let mimeType: string;
      let tempFile: Deno.TempFile | null = null;

      try {
        if (filePath) {
          fileName = options.filename || filePath.split("/").pop() || "unknown";
          const ext = extname(fileName);
          mimeType = ext ? contentType(ext) || "application/octet-stream" : await getMimeTypeFromFileCommand(filePath);
        } else {
          const stdinContent = await readAll(Deno.stdin);
          tempFile = await Deno.makeTempFile();
          fileName = options.filename || tempFile.replace(/^.*[\\\/]/, '');
          await Deno.writeFile(tempFile, stdinContent);
          mimeType = await getMimeTypeFromFileCommand(tempFile);
          filePath = tempFile;
        }

        const client = await setupClient();
        const file = await Deno.readFile(filePath);
        const fileObj = new File([file], fileName, { type: mimeType });
        const cid = await client.uploadFile(fileObj);
        const url = `https://w3s.link/ipfs/${cid}`;

        if (options.clipboard) {
          await clippy.writeText(url);
          console.log('URL copied to clipboard');
        }

        if (options.open) {
          await open(url);
        }

        console.log(url);
      } catch (error) {
        console.error('Error:', error.message);
        Deno.exit(1);
      } finally {
        if (tempFile) {
          await Deno.remove(tempFile);
        }
      }
    })
    .parse(Deno.args);
}

if (import.meta.main) {
  main();
}