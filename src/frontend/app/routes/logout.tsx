import { Form, Link, redirect, useLocation } from "react-router";
import {
	getSession,
	destroySession,
} from "~/sessions.server";
import type { Route } from "./+types/logout";

export async function action({
	request,
}: Route.ActionArgs) {
	const session = await getSession(
		request.headers.get("Cookie"),
	);
	return redirect("/login", {
		headers: {
			"Set-Cookie": await destroySession(session),
		},
	});
}

export default function LogoutRoute() {

	let location = useLocation();
	let params = new URLSearchParams(location.search);
	let from = params.get("from") || "/";

	return (
		<div className="logout_container">
			<h3>Êtes-vous sûr•e de vouloir vous déconnecter ?</h3>

			<div className="row">
				<Form method="post" className="logout_form">
					<button className="btn">Déconnexion</button>
				</Form>
				<Link to={from} className="link_button">Annuler</Link>
			</div>
		</div>
	);
}
