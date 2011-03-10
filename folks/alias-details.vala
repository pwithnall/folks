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
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 */

using GLib;

/**
 * Interface for classes which represent aliasable contacts, such as
 * {@link Persona} and {@link Individual}.
 */
public interface Folks.AliasDetails : Object
{
  /**
   * An alias for the contact.
   *
   * An alias is a user-given name, to be used in UIs as the sole way to
   * represent the contact to the user.
   */
  public abstract string alias { get; set; }
}