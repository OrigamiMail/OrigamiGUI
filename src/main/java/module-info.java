/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/module-info.java to edit this template
 */

module com.pessetto.OrigamiGUI {
    requires javafx.base;
    requires javafx.fxml;
    requires javafx.graphics;
    requires javafx.controls;
    requires java.desktop;
    requires jakarta.mail;
    requires jakarta.activation;
    requires com.pessetto.origamismtp;
    requires javafx.web;
    requires javafx.swing;
    requires jdk.jsobject;
    requires org.jsoup;
    requires java.base;
    requires org.json;

    opens com.pessetto.origamigui.email to javafx.base;
    opens com.pessetto.origamigui.controllers to javafx.fxml;
    opens com.pessetto.origamigui.web to javafx.web;
    
    exports com.pessetto.origamigui.gui to javafx.fxml;
    exports com.pessetto.origamigui.console;
    exports com.pessetto.origamigui.controllers;
}
