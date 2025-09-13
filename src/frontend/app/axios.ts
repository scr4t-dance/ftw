// src/api/axios.ts
import Axios, { type AxiosRequestConfig } from 'axios';

const API_BASE_URL = import.meta.env.API_BASE_URL ?? import.meta.env.VITE_API_BASE_URL ?? "";

export const axiosInstance = Axios.create({
  baseURL: API_BASE_URL,
});

export const customInstance = <T>(
  config: AxiosRequestConfig,
  options?: AxiosRequestConfig,
): Promise<T> => {

  console.log("custom Axios instance init", API_BASE_URL);
  const source = Axios.CancelToken.source();

  const promise = axiosInstance({
    ...config,
    ...options,
    cancelToken: source.token,
  }).then(({ data }) => data);

  // @ts-ignore
  promise.cancel = () => {
    source.cancel('Query was cancelled');
  };

  return promise;
};
