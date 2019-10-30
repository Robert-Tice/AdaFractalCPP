pragma Ada_2012;
pragma Style_Checks (Off);

with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with System;
with Interfaces.C.Extensions;

package Uri_Router_Hh is

   package Class_Capture_Groups is
      type Capture_Groups is limited record
         null;
      end record
        with Import => True,
        Convention => CPP;

      function New_Capture_Groups return Capture_Groups;  -- uri_router.hh:10
      pragma CPP_Constructor (New_Capture_Groups, "_ZN14capture_groupsC1Ev");

      function Size (This : access Capture_Groups) return Int  -- uri_router.hh:11
        with Import => True, 
        Convention => CPP, 
        External_Name => "_ZN14capture_groups4sizeEv";

      function Get_Match (This : access Capture_Groups; Index : Int) return Interfaces.C.Strings.Chars_Ptr  -- uri_router.hh:12
        with Import => True, 
        Convention => CPP, 
        External_Name => "_ZN14capture_groups9get_matchEi";
   end;
   use Class_Capture_Groups;
   type Callback_Function is access procedure (Arg1 : access Capture_Groups; Arg2 : System.Address)
     with Convention => C;  -- uri_router.hh:20

   type Default_Callback is access procedure (Arg1 : Interfaces.C.Strings.Chars_Ptr; Arg2 : System.Address)
     with Convention => C;  -- uri_router.hh:22

   package Class_Uri_Router is
      type Uri_Router is limited record
         null;
      end record
        with Import => True,
        Convention => CPP;

      function New_Uri_Router return Uri_Router;  -- uri_router.hh:34
      pragma CPP_Constructor (New_Uri_Router, "_ZN10uri_routerC1Ev");

      procedure Register_Path
        (This    : access Uri_Router;
         Rgx_Str : Interfaces.C.Strings.Chars_Ptr;
         Cb      : Callback_Function)  -- uri_router.hh:36
        with Import => True, 
        Convention => CPP, 
        External_Name => "_ZN10uri_router13register_pathEPKcPFvP14capture_groupsPvE";

      procedure Register_Default (This : access Uri_Router; Cb : Default_Callback)  -- uri_router.hh:37
        with Import => True, 
        Convention => CPP, 
        External_Name => "_ZN10uri_router16register_defaultEPFvPKcPvE";

      function Match_Path
        (This     : access Uri_Router;
         Path     : Interfaces.C.Strings.Chars_Ptr;
         Response : System.Address) return Extensions.Bool  -- uri_router.hh:38
        with Import => True, 
        Convention => CPP, 
        External_Name => "_ZN10uri_router10match_pathEPKcPv";
   end;
   use Class_Uri_Router;
end Uri_Router_Hh;
