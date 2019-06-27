# Formulário WEBMAIL / CPANEL

Html para personalização de formulário de acesso ao webmail de hospedagens CPANEL

    <form name="form" method="post" action="http://www.dominio.com.br:2095/login/">

    <input type="hidden" name="goto_uri" value="/3rdparty/roundcube/" />

    <input type="text" name="user" value="" placeholder="nome@dominio.com.br" />
    <input type="password" name="pass" value="" autocomplete="off" placeholder="senha:" />

    <input type="submit" value="Entrar" />
        </form>