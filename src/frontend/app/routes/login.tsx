import { data, Form, redirect, useLocation, useNavigate } from "react-router";
import {
  verifyPassword,
  findUserByEmail,
} from "~/auth.server";
import type { Route } from "./+types/login";
import { commitSession, getSession } from "~/sessions.server";
import { Field } from "./index/field";


type RedirectLocationState = {
  redirectTo: Location;
};

export async function loader({
  request,
}: Route.LoaderArgs) {
  const session = await getSession(request.headers.get("Cookie"));

  if (session.has("userId")) {
    // Redirect to the home page if they are already signed in.
    console.log("already signed in")
    // TODO implement logout : return redirect("/");
  }

  return data(
    { error: session.get("error") },
    {
      headers: {
        "Set-Cookie": await commitSession(session),
      },
    },
  );
}


export async function action({ request }: Route.ActionArgs) {

  const session = await getSession(request.headers.get("Cookie"));

  const formData = await request.formData();
  const email = formData.get("email");
  const password = formData.get("password");

  if (!email?.toString()) throw new Error("Email is required");

  const user = await findUserByEmail(email.toString());

  const isValid = await verifyPassword(password?.toString() ?? '', user?.hash ?? "");

  if (!user || !isValid) {
    session.flash("error", "Invalid username/password");

    return redirect("/login", {
      headers: {
        "Set-Cookie": await commitSession(session),
      },
    });
  }

  session.set("userId", user.id);

  let redirectTo = formData.get("redirectTo") as string | null;
  return redirect(redirectTo || "/", {
    headers: {
      "Set-Cookie": await commitSession(session),
    },
  });
}

export default function Login({
  loaderData,
}: Route.ComponentProps) {

  let location = useLocation();
  let params = new URLSearchParams(location.search);
  let from = params.get("from") || "/";

  const { error } = loaderData;

  return (
    <div>
      <h1>Log In</h1>
      {error ? <div className="error">{error}</div> : null}
      <Form method="post">
        <input type="hidden" name="redirectTo" value={from} />
        <Field label="Courriel">
          <input name="email" type="text" required />
        </Field>
        <Field label="Mot de passe">
          <input name="password" type="password" required />
        </Field>
        <button type="submit">Login</button>
      </Form>
    </div>
  );
}
