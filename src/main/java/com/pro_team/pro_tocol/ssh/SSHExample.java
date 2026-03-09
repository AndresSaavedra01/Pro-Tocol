package com.pro_team.pro_tocol.ssh;

import net.schmizz.sshj.SSHClient;
import net.schmizz.sshj.transport.verification.PromiscuousVerifier;

public class SSHExample {

    public static void main(String[] args) throws Exception {


        SSHClient ssh = new SSHClient();

        // aceptar host keys (solo para pruebas)
        ssh.addHostKeyVerifier(new PromiscuousVerifier());

        ssh.connect("192.168.1.10");

        ssh.authPassword("usuario", "password");

        System.out.println("Conectado!");

        ssh.disconnect();
    }
}