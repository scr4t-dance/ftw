// src/api/axios.ts
import Axios, { type AxiosRequestConfig } from 'axios';

export let runtimeBaseURL = '';

// Function to update baseURL dynamically
export const setBaseURL = (url: string) => {
  runtimeBaseURL = url;
};

// Axios instance
export const axiosInstance = Axios.create({});

// Interceptor sets baseURL dynamically
axiosInstance.interceptors.request.use((config) => {
  config.baseURL = runtimeBaseURL;
  return config;
});

 export const customInstance = <T>(

   config: AxiosRequestConfig,

   options?: AxiosRequestConfig,

 ): Promise<T> => {

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
