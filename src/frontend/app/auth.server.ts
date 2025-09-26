import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import { getSession } from "./sessions.server";
import { redirect } from "react-router";
import { userContext } from "./context";

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



export const authMiddleware = async ({
  request,
  context,
}) => {
  const session = await getSession(request);
  const userId = session.get("userId");

  if (!userId) {
    throw redirect("/login");
  }

  const user = verifyToken(userId);
  context.set(userContext, user);
};