import { client } from "./client/client.gen";

const configureApiClient = () => {
    client.interceptors.response.use((response) => {
        if (response.status == 401 && response.headers.has("OAuth-Redirect")) {
            const currentUrl = window.location.href;
            window.location.href = response.headers.get("OAuth-Redirect") + "?redirect=" + encodeURIComponent(currentUrl); 
        }

        return response;
    });
}

import type { CreateClientConfig } from './client/client.gen';

export const createClientConfig: CreateClientConfig = (config) => {
    //console.log(config);
    return {
        ...config,
        credentials: "include"
    };
};

export default configureApiClient;