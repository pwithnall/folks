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

using Folks;
using Gee;
using GLib;

private class Folks.Inspect.Commands.Personas : Folks.Inspect.Command
{
  public override string name
    {
      get { return "personas"; }
    }

  public override string description
    {
      get
        {
          return "Inspect the personas currently present in the aggregator";
        }
    }

  public override string help
    {
      get
        {
          return "personas                  List all known personas.\n" +
              "personas [persona UID]    Display the details of the " +
              "specified persona.";
        }
    }

  public Personas (Client client)
    {
      base (client);
    }

  public override void run (string? command_string)
    {
      foreach (var individual in this.client.aggregator.individuals.values)
        {
          foreach (Persona persona in individual.personas)
            {
              /* Either list all personas, or only list the one specified */
              if (command_string != null && persona.uid != command_string)
                continue;

              Utils.print_persona (persona);

              if (command_string == null)
                Utils.print_line ("");
            }
        }
    }

  public override string[]? complete_subcommand (string subcommand)
    {
      /* @subcommand should be a persona UID */
      return Readline.completion_matches (subcommand,
          Utils.persona_uid_completion_cb);
    }
}
