module mail {
    requires java.desktop;
    requires java.security.sasl;
    requires java.xml;

    requires transitive java.datatransfer;
    requires transitive java.logging;

    exports com.sun.mail.auth;
    exports com.sun.mail.handlers;
    exports com.sun.mail.iap;
    exports com.sun.mail.imap;
    exports com.sun.mail.imap.protocol;
    exports com.sun.mail.pop3;
    exports com.sun.mail.smtp;
    exports com.sun.mail.util;
    exports com.sun.mail.util.logging;
    exports javax.mail;
    exports javax.mail.event;
    exports javax.mail.internet;
    exports javax.mail.search;
    exports javax.mail.util;

}
