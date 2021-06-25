with System; use System;
with Glib; use Glib;
with Gdk.Event; use Gdk.Event;
with Gdk.Types; use Gdk.Types;
with Gtk.Accel_Group; use Gtk.Accel_Group;
with Gtk.Object; use Gtk.Object;
with Gtk.Enums; use Gtk.Enums;
with Gtk.Style; use Gtk.Style;
with Gtk.Widget; use Gtk.Widget;

package body Help_Pkg.Callbacks is

   use Gtk.Arguments;

   ------------------------
   -- On_Help_Ok_Clicked --
   ------------------------

   procedure On_Help_Ok_Clicked
     (Object : access Gtk_Button_Record'Class)
   is
   begin
      Destroy(Help);
   end On_Help_Ok_Clicked;

end Help_Pkg.Callbacks;
