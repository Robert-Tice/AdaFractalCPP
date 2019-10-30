with Ada.Calendar; use Ada.Calendar;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Conversion;

with AWS.MIME;
with AWS.Messages;
with AWS.Response;

with AWS.Utils; use AWS.Utils;

with Fractal;

with Interfaces.C.Strings; use Interfaces.C.Strings;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;

package body Router_Cb is
   
   procedure Init
   is      
   begin
      Float_Julia_Fractal.Init (Viewport => Viewport);
      Fixed_Julia_Fractal.Init (Viewport => Viewport);
      
      Class_Uri_Router.Register_Path (This => Route'Access,
                                      Rgx_Str => New_String (Str => "^\/$"),
                                      Cb => Index_Worker'Access);
      Class_Uri_Router.Register_Path (This => Route'Access,
                                      Rgx_Str => New_String (Str => "^\/(fixed|float)_fractal$"),
                                      Cb => Fractal_Worker'Access);
      Class_Uri_Router.Register_Path (This => Route'Access,
                                      Rgx_Str => New_String (Str => "^\/reset$"),
                                      Cb => Reset_Worker'Access);
      Class_Uri_Router.Register_Path (This => Route'Access,
                                      Rgx_Str => New_String (Str => "^\/quit$"),
                                      Cb => Quit_Worker'Access);
      Class_Uri_Router.Register_Path (This => Route'Access,
                                      Rgx_Str => New_String (Str => "^\/compute_time$"),
                                      Cb => Compute_Time_Worker'Access);
      Class_Uri_Router.Register_Path (This => Route'Access,
                                      Rgx_Str => New_String (Str => "^\/window\|(\d+)\|(\d+)\|(\d+)\|(\d+)\|(\d+)$"),
                                      Cb => Window_Worker'Access);
      
--      Class_Uri_Router.Register_Default (This => Route'Access,
--                                         Cb   => Default_Worker'Access);
   end Init;
   
   procedure Color_Pixel (Z_Escape    : Boolean;
                          Iter_Escape : Natural;
                          Px          : out RGB888_Pixel)
   is
      Value : constant Integer := 765 * (Iter_Escape - 1) / Max_Iterations;
   begin
      if Z_Escape then
         if Value > 510 then
            Px := RGB888_Pixel'(Red   => Color'Last - Frame_Counter,
                                Green => Color'Last,
                                Blue  => Color (Value rem Integer (Color'Last)),
                                Alpha => Color'Last);
         elsif Value > 255 then
            Px := RGB888_Pixel'(Red   => Color'Last - Frame_Counter,
                                Green => Color (Value rem Integer (Color'Last)),
                                Blue  => Color'First + Frame_Counter,
                                Alpha => Color'Last);
         else
            Px := RGB888_Pixel'(Red   => Color (Value rem Integer (Color'Last)),
                                Green => Color'First + Frame_Counter,
                                Blue  => Color'First,
                                Alpha => Color'Last);
         end if;
      else
         Px := RGB888_Pixel'(Red   => Color'First + Frame_Counter,
                             Green => Color'First + Frame_Counter,
                             Blue  => Color'First + Frame_Counter,
                             Alpha => Color'Last);
      end if;
      
      
   end Color_Pixel;

   function Router (Request : AWS.Status.Data) return AWS.Response.Data
   is
      URI      : constant String := AWS.Status.URI (Request); 
      Filename : constant String := "web/" & URI (2 .. URI'Last);
      
      Response : aliased AWS.Response.Data
        with Volatile;
   begin
      
      if not Class_Uri_Router.Match_Path (This     => Route'Access,
                                          Path     => New_String (Str => URI),
                                          Response => Response'Address) then
      
         if AWS.Utils.Is_Regular_File (Filename) then
            Response :=  AWS.Response.File
              (Content_Type => AWS.MIME.Content_Type (Filename),
               Filename     => Filename);
         
            --  404 not found
         else
            Put_Line ("Could not find file: " & Filename);

            Response := AWS.Response.Acknowledge
              (AWS.Messages.S404,
               "<p>Page '" & URI & "' Not found.");
         end if;
      end if;  
      
      return Response;
   end Router;
   
   procedure Default_Worker (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : System.Address)
   is
      Response : AWS.Response.Data
        with Address => Arg2, Import;
      
      URI : String := Value (Item => Arg1);
      Filename : constant String := "web/" & URI (2 .. URI'Last);
   begin      
      if AWS.Utils.Is_Regular_File (Filename) then
         Response:=  AWS.Response.File
           (Content_Type => AWS.MIME.Content_Type (Filename),
            Filename     => Filename);
         
         --  404 not found
      else
         Put_Line ("Could not find file: " & Filename);

         Response := AWS.Response.Acknowledge
           (AWS.Messages.S404,
            "<p>Page '" & URI & "' Not found.");
      end if;
      
   end Default_Worker;
   
   procedure Index_Worker (arg1 : access Class_Capture_Groups.capture_groups; arg2 : System.Address)
   is
      Response : aliased AWS.Response.Data
        with Address => Arg2, Import;
   begin
      Response := AWS.Response.File (AWS.MIME.Text_HTML, "web/html/index.html");
   end Index_Worker;
   
   procedure Fractal_Worker (arg1 : access Class_Capture_Groups.capture_groups; arg2 : System.Address)
   is
      Response : AWS.Response.Data
        with Address => Arg2, Import;
      
      Fractal_Type : Computation_Enum;
      
      function Buffer_To_Stream is new 
        Ada.Unchecked_Conversion (Source => Buffer_Access,
                                  Target => Stream_Element_Array_Access);
      
      Data_Stream  : constant Stream_Element_Array_Access := 
                       Buffer_To_Stream (RawData);
      
      Buffer_Size  : Stream_Element_Offset;
      
      Fixed_String : constant String := "fixed";
   begin  
      
      if Value (Item => Class_Capture_Groups.Get_Match (this  => Arg1,
                                                        Index => 1)) = Fixed_String then
         Fractal_Type := Fixed_Type;
      else
         Fractal_Type := Float_Type;
      end if;
      
      Buffer_Size := Stream_Element_Offset (Compute_Image (Comp_Type => Fractal_Type));
      Response := AWS.Response.Build
        (Content_Type  => AWS.MIME.Application_Octet_Stream,
         Message_Body  => Data_Stream (Data_Stream'First ..
               Data_Stream'First + Buffer_Size));
      
   end Fractal_Worker;
      
   procedure Reset_Worker (arg1 : access Class_Capture_Groups.capture_groups; arg2 : System.Address)
   is
      Response : AWS.Response.Data
        with Address => Arg2, Import;
   begin
      Viewport.Zoom := 10;
      Viewport.Center.X := Viewport.Width / 2;
      Viewport.Center.Y := Viewport.Height / 2;
      
      Float_Julia_Fractal.Set_Size (Viewport => Viewport);
      
      Fixed_Julia_Fractal.Set_Size (Viewport => Viewport);
      
      Put_Line ("Width:" & Viewport.Width'Img & 
                  " Height:" & Viewport.Height'Img & 
                  " Zoom:" & Viewport.Zoom'Img & 
                  " MouseX:" & Viewport.Center.X'Img &
                  " MouseY:" & Viewport.Center.Y'Img);
      Response := AWS.Response.Build (AWS.MIME.Text_HTML, "reset");
   end Reset_Worker;
   
   procedure Quit_Worker (arg1 : access Class_Capture_Groups.capture_groups; arg2 : System.Address)
   is
      Response : AWS.Response.Data
        with Address => Arg2, Import;
   begin
      Router_Cb.Server_Alive := False;
      Put_Line ("quitting...");
      Response := AWS.Response.Build (AWS.MIME.Text_HTML, "quitting...");
   end Quit_Worker;
         
   procedure Compute_Time_Worker (arg1 : access Class_Capture_Groups.capture_groups; arg2 : System.Address)
   is
      Response : AWS.Response.Data
        with Address => Arg2, Import;
   begin
      Response := AWS.Response.Build 
        (AWS.MIME.Text_HTML, Duration'Image (Compute_Time));
   end Compute_Time_Worker;
         
   procedure Window_Worker (Arg1 : access Class_Capture_Groups.Capture_Groups; Arg2 : System.Address)
   is
      Response : AWS.Response.Data
        with Address => Arg2, Import;
      
      Width    : Natural := Natural'Value (Value (Item => Class_Capture_Groups.Get_Match (This  => Arg1,
                                                                                           Index => 1)));
      Height   : Natural := Natural'Value (Value (Item => Class_Capture_Groups.Get_Match (This  => Arg1,
                                                                                           Index => 2)));
      Zoom     : Natural := Natural'Value (Value (Item => Class_Capture_Groups.Get_Match (This  => Arg1,
                                                                                           Index => 3)));
      MouseX   : Natural := Natural'Value (Value (Item => Class_Capture_Groups.Get_Match (This  => Arg1,
                                                                                           Index => 4)));
      MouseY   : Natural := Natural'Value (Value (Item => Class_Capture_Groups.Get_Match (This  => Arg1,
                                                                                           Index => 5)));
   begin
      if Width >= 0 then
         if Width > ImgWidth'Last then
            Width := ImgWidth'Last;
         end if;
         
         Viewport.Width := Width;
      end if;
      
      if Height >= 0 then 
         if Height > ImgHeight'Last then
            Height := ImgHeight'Last;
         end if;
         
         Viewport.Height := Height;
      end if;
      
      if Zoom /= 0 then
         Zoom := Viewport.Zoom + Zoom;
         
         if Zoom > ImgZoom'Last then
            Zoom := ImgZoom'Last;
         elsif Zoom < ImgZoom'First then
            Zoom := ImgZoom'First;
         end if;
         
         Viewport.Zoom := Zoom;
      end if;
      
      if MouseX >= 0 then 
         if MouseX > ImgWidth'Last then
            MouseX := ImgWidth'Last;
         elsif MouseX < ImgWidth'First then
            MouseX := ImgWidth'First;
         end if;
         
         Viewport.Center.X := MouseX;
      end if;
      
      if MouseY >= 0 then
         if MouseY > ImgHeight'Last then
            MouseY := ImgHeight'Last;
         elsif MouseY < ImgHeight'First then
            MouseY := ImgHeight'First;
         end if;
         
         Viewport.Center.Y := MouseY;
      end if;

      Put_Line ("Float");
      Float_Julia_Fractal.Set_Size (Viewport => Viewport);
      
      Put_Line ("Fixed");
      Fixed_Julia_Fractal.Set_Size (Viewport => Viewport);

      Put_Line ("Width:" & Viewport.Width'Img & 
                  " Height:" & Viewport.Height'Img & 
                  " Zoom:" & Viewport.Zoom'Img & 
                  " MouseX:" & Viewport.Center.X'Img &
                  " MouseY:" & Viewport.Center.Y'Img);
      Response := AWS.Response.Build (AWS.MIME.Text_HTML, "Success");
      
   end Window_Worker;
   
   procedure Increment_Frame
   is
   begin
      if Cnt_Up then
         if Frame_Counter = Color'Last then
            Cnt_Up := not Cnt_Up;
            return;
         else
            Frame_Counter := Frame_Counter + 5;
            return;
         end if;
      end if;

      if Frame_Counter = Color'First then
         Cnt_Up := not Cnt_Up;
         return;
      end if;

      Frame_Counter := Frame_Counter - 5;
   end Increment_Frame;
   
   function Compute_Image (Comp_Type : Computation_Enum) 
                           return Buffer_Offset
   is
      Start_Time : constant Time := Clock;
      Ret : Buffer_Offset;
   begin
      
      case Comp_Type is
         when Fixed_Type =>
            Increment_Frame;
            Fixed_Julia_Fractal.Calculate_Image 
              (Buffer => RawData);
            Ret := Fixed_Julia_Fractal.Get_Buffer_Size;
         when Float_Type =>
            Increment_Frame;
            Float_Julia_Fractal.Calculate_Image 
              (Buffer => RawData);
            Ret := Float_Julia_Fractal.Get_Buffer_Size;
      end case;
      
      Compute_Time := (Clock - Start_Time) * 1000.0; 
      
--      Put_Line ("Time:" & Duration'Image (Compute_Time) & " ms");
       
      return Ret;
   end Compute_Image;
   
end Router_Cb;
