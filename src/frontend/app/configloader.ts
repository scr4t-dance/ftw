// src/configLoader.ts
import { setBaseURL } from './axios';

export const loadRuntimeConfig = async () => {
  try {
    const response = await fetch('/config.json');
    const config = await response.json();
    if (config.API_BASE_URL) {
      setBaseURL(config.API_BASE_URL);
    }
  } catch (error) {
    console.error('Failed to load runtime config', error);
  }
};
