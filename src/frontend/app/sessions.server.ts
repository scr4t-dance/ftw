import { createCookieSessionStorage } from "react-router";

export type SessionData = {
  userId: string;
};

type SessionFlashData = {
  error: string;
};

const { getSession, commitSession, destroySession } =
  createCookieSessionStorage<SessionData, SessionFlashData>(
    {
      // a Cookie from `createCookie` or the CookieOptions to create one
      cookie: {
        name: "__session",

        // all of these are optional
        // domain: "localhost", // deactivated for webkit (safari) browsers

        // Expires can also be set (although maxAge overrides it when used in combination).
        // Note that this method is NOT recommended as `new Date` creates only one date on each server deployment, not a dynamic date in the future!
        //
        // expires: new Date(Date.now() + 60_000),
        httpOnly: true,
        maxAge: 60_000,
        path: "/",
        sameSite: "strict",
        secrets: ["s3cret1"],
        // TODO : change `secure` to true for deployment on https
        // is not supported by safari (webkit) in local tests
        //secure: process.env.NODE_ENV === "production",
      },
    },
  );

export { getSession, commitSession, destroySession };
