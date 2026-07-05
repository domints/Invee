import type { UserInfoDto } from "@/client";
import { ref } from "@vue/runtime-dom";
import { defineStore } from "pinia";

// export const useUserStore = defineStore('user', {

//     state: () => ({ loggedIn: false, userInfo: {} as UserInfoDto })
// })

export const useUserStore = defineStore('user', () => {
    const loggedIn = ref(false);
    const user = ref(null as UserInfoDto | null);

    function logout() {
        user.value = null;
        loggedIn.value = false;
    }

    function login(loggedUser: UserInfoDto) {
        if (loggedUser) {
            user.value = loggedUser;
            loggedIn.value = true;
        }
        else {
            logout();
        }
    }

    return { loggedIn, user, login, logout };
});