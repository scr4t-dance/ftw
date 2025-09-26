import { createContext } from "react-router";
import type { SessionData } from "~/sessions.server";

export const userContext = createContext<SessionData | null>(null);
