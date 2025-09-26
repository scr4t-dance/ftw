import type { ActionFunctionArgs } from "react-router";
import { redirect } from "react-router";
import {
  hashPassword,
  createToken,
} from "~/auth.server";

export async function action({
  request,
}: ActionFunctionArgs) {
  const formData = await request.formData();
  const email = formData.get("email") as string;
  const password = formData.get("password") as string;

  // Server-only operations
  const hashedPassword = await hashPassword(password);
  console.log(email, hashedPassword);
  const user = {userId: email};

  const token = createToken(user.userId);

  return redirect("/dashboard", {
    headers: {
      "Set-Cookie": `token=${token}; HttpOnly; Secure; SameSite=Strict`,
    },
  });
}

export default function Login() {
  return (
    <form method="post">
      <input name="email" type="email" required />
      <input name="password" type="password" required />
      <button type="submit">Login</button>
    </form>
  );
}
