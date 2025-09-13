// src/api/axios.ts
import Axios, { type AxiosRequestConfig } from 'axios';


// Axios instance
export const axiosInstance = Axios.create({});

export const customInstance = <T>(
  config: AxiosRequestConfig,
  options?: AxiosRequestConfig,
): Promise<T> => {

  const source = Axios.CancelToken.source();

  const promise = axiosInstance({
    ...config,
    ...options,
    baseURL: import.meta.env.API_BASE_URL,
    cancelToken: source.token,
  }).then(({ data }) => data);

  // @ts-ignore
  promise.cancel = () => {
    source.cancel('Query was cancelled');
  };

  return promise;
};
