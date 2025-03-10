#pragma once

#include <libintl.h>

#include <QString>

const QString GETTEXT_DOMAIN = "cinny.danfro";

#define _(value) gettext(value)
#define N_(value) gettext(value)
