/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtkhpaned.c -

  $Author: mutoh $
  $Date: 2003/01/19 14:28:25 $

  Copyright (C) 2002,2003 The Ruby-GNOME2 Project
  Copyright (C) 1998-2000 Yukihiro Matsumoto,
                          Daisuke Kanda,
                          Hiroshi Igarashi
************************************************/

#include "global.h"

static VALUE
hpaned_initialize(self)
    VALUE self;
{
    RBGTK_INITIALIZE(self, gtk_hpaned_new());
    return Qnil;
}

void 
Init_gtk_hpaned()
{
    VALUE gHPaned = G_DEF_CLASS(GTK_TYPE_HPANED, "HPaned", mGtk);

    rb_define_method(gHPaned, "initialize", hpaned_initialize, 0);
}
