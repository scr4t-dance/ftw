import { createContext } from "react-router";
import type { User } from "~/auth.server";

export const userContext = createContext<User | null>(null);
