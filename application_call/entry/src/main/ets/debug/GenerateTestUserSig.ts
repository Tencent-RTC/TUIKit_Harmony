// Copyright (c) 2023 Tencent. All rights reserved.

import buffer from "@ohos.buffer";
import CryptoJS from "@ohos/crypto-js";
import pako from "pako";

/**
 * Tencent Cloud SDKAppId, which needs to be replaced with the SDKAppId under your own account.
 *
 * Enter Tencent Cloud IM to create an application, and you can see the SDKAppId, which is the unique identifier used by Tencent Cloud to distinguish customers.
 */
export const SDKAPPID = 0;

/**
 *  Signature expiration time, it is recommended not to set it too short
 *
 *  Time unit: seconds
 *  Default time: 7 x 24 x 60 x 60 = 604800 = 7 days
 */
const EXPIRETIME = 604800;

/**
 * Encryption key used for calculating the signature, the steps to obtain it are as follows:
 *
 * step1. Enter Tencent Cloud IM, if you do not have an application yet, create one,
 * step2. Click "Application Configuration" to enter the basic configuration page, and further find the "Account System Integration" section.
 * step3. Click the "View Key" button, you can see the encryption key used to calculate UserSig, please copy and paste it into the following variable
 *
 * Note: This solution is only applicable to debugging demos.
 * Before going online officially, please migrate the UserSig calculation code and keys to your backend server to avoid traffic theft caused by encryption key leakage.
 */
const SECRETKEY = "";

export function genTestUserSig(userId: string): string {
  return genTlsSignature(userId, SDKAPPID, EXPIRETIME, SECRETKEY);
}

function genTlsSignature(userId: string, sdkAppId: number, expireTime: number, key: string): string {
  const currentTime = (new Date().getTime() / 1000).toFixed();

  const data = `TLS.identifier:${userId}\nTLS.sdkappid:${sdkAppId}\nTLS.time:${currentTime}\nTLS.expire:${expireTime}\n`;
  const hashedData = hMacSha256(key, data);

  const content = new Object();
  content["TLS.ver"] = "2.0";
  content["TLS.identifier"] = userId;
  content["TLS.sdkappid"] = sdkAppId;
  content["TLS.expire"] = expireTime;
  content["TLS.time"] = currentTime;
  content["TLS.sig"] = hashedData;

  const deflatedContent = deflate(JSON.stringify(content));
  const result = base64Url(deflatedContent);
  return result;
}

function hMacSha256(key: string, message: string): string {
  const hmac = CryptoJS.HmacSHA256(message, key);
  const result = hmac.toString(CryptoJS.enc.Base64);
  return result;
}

function deflate(data: string): Uint8Array {
  const input = new Uint8Array(buffer.from(data).buffer);
  const result = pako.deflate(input);
  return result;
}

function base64Url(data: Uint8Array): string {
  const base64 = buffer.from(data).toString("base64");
  let result = "";
  for (let c of base64) {
    switch (c) {
      case "+":
        result += "*";
        break;
      case "/":
        result += "-";
        break;
      case "=":
        result += "_";
        break;
      default:
        result += c;
        break;
    }
  }
  return result;
}
