/*
 * Copyright (C) 2010 Collabora Ltd.
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 */

using GLib;
using Gee;
using Xml;
using Folks;

/*
 * Command line application to import meta-contact information from various
 * places into libfolks' key file backend.
 *
 * Used as follows:
 *   folks-import [--source=pidgin] [--source-filename=~/.purple/blist.xml]
 */

public class Folks.ImportTool : Object
{
  private static string source;
  private static string source_filename;

  private static const OptionEntry[] options =
    {
      { "source", 's', 0, OptionArg.STRING, ref ImportTool.source,
          "Source backend name (default: 'pidgin')", "name" },
      { "source-filename", 0, 0, OptionArg.FILENAME,
          ref ImportTool.source_filename,
          "Source filename (default: specific to source backend)", null },
      { null }
    };

  public static int main (string[] args)
    {
      OptionContext context = new OptionContext ("— import meta-contact " +
          "information to libfolks");
      context.add_main_entries (ImportTool.options, "folks");

      try
        {
          context.parse (ref args);
        }
      catch (OptionError e)
        {
          stderr.printf ("Couldn't parse command line options: %s\n",
              e.message);
          return 1;
        }

      /* We only support importing from Pidgin at the moment */
      if (source == null || source.strip () == "")
        source = "pidgin";

      /* FIXME: We need to create this, even though we don't use it, to prevent
       * debug message spew, as its constructor initialises the log handling.
       * bgo#629096 */
      IndividualAggregator aggregator = new IndividualAggregator ();
      aggregator = null;

      /* Create a main loop and start importing */
      MainLoop main_loop = new MainLoop ();

      bool success = false;
      ImportTool.import.begin ((o, r) =>
        {
          success = ImportTool.import.end (r);
          main_loop.quit ();
        });

      main_loop.run ();

      return success ? 0 : 1;
    }

  private static async bool import ()
    {
      BackendStore backend_store = new BackendStore ();

      try
        {
          yield backend_store.load_backends ();
        }
      catch (GLib.Error e1)
        {
          stderr.printf ("Couldn't load the backends: %s\n", e1.message);
          return false;
        }

      /* Get the key-file backend */
      Backend kf_backend = backend_store.get_backend_by_name ("key-file");

      if (kf_backend == null)
        {
          stderr.printf ("Couldn't load the 'key-file' backend.\n");
          return false;
        }

      try
        {
          yield kf_backend.prepare ();
        }
      catch (GLib.Error e2)
        {
          stderr.printf ("Couldn't prepare the 'key-file' backend: %s\n",
              e2.message);
          return false;
        }

      /* Get its only PersonaStore */
      PersonaStore destination_store;
      GLib.List<unowned PersonaStore> stores =
          kf_backend.persona_stores.get_values ();

      if (stores == null)
        {
          stderr.printf ("Couldn't load the 'key-file' backend's persona " +
              "store.\n");
          return false;
        }

      try
        {
          destination_store = stores.data;
          yield destination_store.prepare ();
        }
      catch (GLib.Error e3)
        {
          stderr.printf ("Couldn't prepare the 'key-file' backend's persona " +
              "store: %s\n", e3.message);
          return false;
        }

      if (source == "pidgin")
        {
          Importer importer = new Importers.Pidgin ();

          try
            {
              /* Import! */
              yield importer.import (destination_store,
                  ImportTool.source_filename);
            }
          catch (ImportError e)
            {
              stderr.printf ("Error: %s\n", e.message);
              return false;
            }

          /* Wait for the PersonaStore to finish writing its changes to disk */
          yield destination_store.flush ();

          return true;
        }
      else
        {
          stderr.printf ("Unrecognised source backend name '%s'. " +
              "'pidgin' is currently the only supported source backend.\n",
              source);
          return false;
        }
    }
}

public errordomain Folks.ImportError
{
  MALFORMED_INPUT,
}

public abstract class Folks.Importer : Object
{
  public abstract async uint import (PersonaStore destination_store,
      string? source_filename) throws ImportError;
}
