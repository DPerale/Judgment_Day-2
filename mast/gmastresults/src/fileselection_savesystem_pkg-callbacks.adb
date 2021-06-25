with System; use System;
with Glib; use Glib;
with Gdk.Event; use Gdk.Event;
with Gdk.Types; use Gdk.Types;
with Gtk.Accel_Group; use Gtk.Accel_Group;
with Gtk.Object; use Gtk.Object;
with Gtk.Enums; use Gtk.Enums;
with Gtk.Style; use Gtk.Style;
with Gtk.Widget; use Gtk.Widget;
with Gtk.Label; use Gtk.Label;
with Error_Window_Pkg; use Error_Window_Pkg;
with Mast_Actions;
with Ada.Text_IO;

package body Fileselection_Savesystem_Pkg.Callbacks is

   use Gtk.Arguments;

   ---------------------------
   -- On_Ok_Button1_Clicked --
   ---------------------------

   procedure On_Ok_Button1_Clicked
     (Object : access Gtk_Button_Record'Class)
   is
      Filename : String:=Get_Filename(Fileselection_Savesystem);
   begin
      Mast_Actions.Save_System(Filename);
      Destroy(Fileselection_Savesystem);
   exception
      when Ada.Text_IO.Name_Error | Ada.Text_IO.Status_Error |
        Ada.Text_IO.Use_Error =>
         Destroy(Fileselection_Savesystem);
         Gtk_New (Error_Window);
         Set_Position(Error_Window,Win_Pos_Mouse);
         Show_All (Error_Window);
         Set_Text(Error_Window.Label_Error,"Error while saving file in "&
                  Filename);
         Set_Modal(Error_Window,True);
   end On_Ok_Button1_Clicked;

   -------------------------------
   -- On_Cancel_Button1_Clicked --
   -------------------------------

   procedure On_Cancel_Button1_Clicked
     (Object : access Gtk_Button_Record'Class)
   is
   begin
      Destroy(Fileselection_Savesystem);
   end On_Cancel_Button1_Clicked;

end Fileselection_Savesystem_Pkg.Callbacks;
