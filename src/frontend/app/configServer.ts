import fs from 'fs';
import path from 'path';

export const loadServerConfig = () => {
  try {
    // Resolve the public folder path
    const filePath = path.resolve(process.cwd(), 'public/config.json');
    const raw = fs.readFileSync(filePath, 'utf-8');
    return JSON.parse(raw);
  } catch (error) {
    console.error('Failed to load server config', error);
    return {};
  }
};
