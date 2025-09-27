import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import { getSession } from "./sessions.server";
import { redirect, useLocation } from "react-router";
import { userContext } from "./context";

export type User = {
  id: string,
  hash: string
};

const JWT_SECRET = process.env.JWT_SECRET!;

export function hashPassword(password: string) {
  return bcrypt.hash(password, 10);
}

export function verifyPassword(
  password: string,
  hash: string
) {
  return bcrypt.compare(password, hash);
}

export function createToken(userId: string) {
  return jwt.sign({ userId }, JWT_SECRET, {
    expiresIn: "7d",
  });
}

export function verifyToken(token: string) {
  return jwt.verify(token, JWT_SECRET) as {
    userId: string;
  };
}


export async function findUserByEmail(email: string) {
  const email_data: User[] = [{ id: "test", hash: await hashPassword("test") }];

  return email_data.find((user) => user.id === email);
}


export const authMiddleware = async ({
  request,
  context,
}) => {

  let params = new URLSearchParams();
  params.set("from", new URL(request.url).pathname);

  const session = await getSession(request.headers.get("Cookie"));
  const userId = session.get("userId");

  console.log("EventsHome middleware", userId);
  if (!userId) {
    return redirect("/login?" + params.toString());
  }

  const user = await findUserByEmail(userId);

  context.set(userContext, user ?? null);

};