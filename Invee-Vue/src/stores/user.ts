import type { UserInfoDto } from "@/client";
import { ref } from "@vue/runtime-dom";
import { defineStore } from "pinia";

// export const useUserStore = defineStore('user', {

//     state: () => ({ loggedIn: false, userInfo: {} as UserInfoDto })
// })

export const useUserStore = defineStore('user', () => {
    let currentUser = sessionStorage.getItem("currentUser");
    const loggedIn = ref(!!currentUser);
    const user = ref(currentUser ? JSON.parse(currentUser) as UserInfoDto : null);

    function logout() {
        sessionStorage.removeItem("currentUser");
        user.value = null;
        loggedIn.value = false;
    }

    function login(loggedUser: UserInfoDto) {
        if (loggedUser) {
            sessionStorage.setItem("currentUser", JSON.stringify(loggedUser));
            user.value = loggedUser;
            loggedIn.value = true;
        }
        else {
            logout();
        }
    }

    return { loggedIn, user, login, logout };
});