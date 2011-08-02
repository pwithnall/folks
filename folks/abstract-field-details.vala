/*
 * Copyright (C) 2011 Collabora Ltd.
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
 *       Marco Barisione <marco.barisione@collabora.co.uk>
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 */

using GLib;
using Gee;

/**
 * Object representing any type of value that can have some vCard-like
 * parameters associated with it.
 *
 * Some contact details, like phone numbers or URLs, can have some
 * extra details associated with them.
 * For instance, a phone number expressed in vcard notation as
 * `tel;type=work,voice:(111) 555-1234` would be represented as
 * a AbstractFieldDetails with value "(111) 555-1234" and with parameters
 * `['type': ('work', 'voice')]`.
 *
 * The parameter name "TYPE" with values "work", "home", or "other" are common
 * amongst most vCard attributes (and thus most AbstractFieldDetails-derived
 * classes). A TYPE of "perf" may be used to indicate a preferred
 * AbstractFieldDetails.value amongst many. See specific classes for information
 * on additional parameters and values specific to that class.
 *
 * See [[http://www.ietf.org/rfc/rfc2426.txt|RFC2426]] for more details on
 * pre-defined parameter names and values.
 *
 * @since UNRELEASED
 */
public abstract class Folks.AbstractFieldDetails<T> : Object
{
  private T _value;
  /**
   * The value of the field.
   *
   * The value of the field, the exact type and content of which depends on what
   * the structure is used for.
   *
   * @since UNRELEASED
   */
  public virtual T @value
    {
      get { return this._value; }
      set { this._value = value; }
    }

  private MultiMap<string, string> _parameters =
      new HashMultiMap<string, string> ();
  /**
   * The parameters associated with the value.
   *
   * A multi-map of the parameters associated with
   * {@link Folks.AbstractFieldDetails.value}. The keys are the names of
   * the parameters, while the values are a list of strings.
   *
   * @since UNRELEASED
   */
  public virtual MultiMap<string, string> parameters
    {
      get { return this._parameters; }
      set
        {
          if (value == null)
            this._parameters.clear ();
          else
            this._parameters = value;
        }
    }

  /**
   * Get the values for a parameter
   *
   * @param parameter_name the parameter name
   * @return a collection of values for `parameter_name` or `null` (i.e. no
   * collection) if there are no such parameters.
   *
   * @since UNRELEASED
   */
  public Collection<string>? get_parameter_values (string parameter_name)
    {
      if (this.parameters.contains (parameter_name) == false)
        {
          return null;
        }

      return this.parameters.get (parameter_name).read_only_view;
    }

  /**
   * Add a new value for a parameter.
   *
   * If there is already a parameter called `parameter_name` then
   * `parameter_value` is added to the existing ones.
   *
   * @param parameter_name the name of the parameter
   * @param parameter_value the value to add
   *
   * @since UNRELEASED
   */
  public void add_parameter (string parameter_name, string parameter_value)
    {
      this.parameters.set (parameter_name, parameter_value);
    }

  /**
   * Set the value of a parameter.
   *
   * Sets the parameter called `parameter_name` to be `parameter_value`.
   * If there were already parameters with the same name they are replaced.
   *
   * @param parameter_name the name of the parameter
   * @param parameter_value the value to add
   *
   * @since UNRELEASED
   */
  public void set_parameter (string parameter_name, string parameter_value)
    {
      this.parameters.remove_all (parameter_name);
      this.parameters.set (parameter_name, parameter_value);
    }

  /**
   * Extend the existing parameters.
   *
   * Merge the parameters from `additional` into the existing ones.
   *
   * @param additional the parameters to add
   *
   * @since UNRELEASED
   */
  public void extend_parameters (MultiMap<string, string> additional)
    {
      foreach (var name in additional.get_keys ())
        {
          var values = additional.get (name);
          foreach (var val in values)
            {
              this.add_parameter (name, val);
            }
        }
    }

  /**
   * Remove all instances of a parameter.
   *
   * @param parameter_name the name of the parameter
   *
   * @since UNRELEASED
   */
  public void remove_parameter_all (string parameter_name)
    {
      this.parameters.remove_all (parameter_name);
    }

  /**
   * An equality function for {@link AbstractFieldDetails}.
   *
   * This defaults to string comparison of the
   * {@link AbstractFieldDetails.value}s if the generic type is string;
   * otherwise, direct pointer comparison of the
   * {@link AbstractFieldDetails.value}s.
   *
   * @param that another {@link AbstractFieldDetails}
   *
   * @return whether the elements are equal
   *
   * @since UNRELEASED
   */
  public virtual bool equal (AbstractFieldDetails<T> that)
    {
      EqualFunc equal_func = direct_equal;

      if (typeof (T) == typeof (string))
        equal_func = str_equal;

      if ((this.get_type () != that.get_type ()) ||
          !equal_func (this.value, that.value))
        {
          return false;
        }

      /* Check that the parameter names and their values match exactly in both
       * AbstractFieldDetails objects. */
      if (this.parameters.size != that.parameters.size)
        return false;

      foreach (var param in this.parameters.get_keys ())
        {
          /* Since these parameters are meant to model vCard parameters, we
           * should compare on a case-insensitive basis. However, this leads to
           * ambiguity in the case:
           *
           *   this.parameters = {"foo": {"bar"}}
           *   that.parameters = {"foo": {"bar"}, "FOO": {"qux"}}
           *
           * So parameter names should normalised elsewhere (either in the
           * insertion functions (with a big warning for the clients) or in the
           * clients themselves).
           *
           * Note that parameter values can't be normalised in general, since
           * they can be user-set labels.
           */
          if (!that.parameters.contains (param))
            return false;

          var this_param_values = this.parameters.get_values ();
          var that_param_values = that.parameters.get_values ();

          if (this_param_values.size != that_param_values.size)
            return false;

          foreach (var param_val in this.parameters.get_values ())
            {
              if (!that_param_values.contains (param_val))
                return false;
            }
        }

      return true;
    }

  /**
   * A hash function for the {@link AbstractFieldDetails}.
   *
   * This defaults to a string hash of the
   * {@link AbstractFieldDetails.value} if the generic type is string;
   * otherwise, direct hash of the {@link AbstractFieldDetails.value}.
   *
   * @return the hash value
   *
   * @since UNRELEASED
   */
  public virtual uint hash ()
    {
      HashFunc hash_func = direct_hash;

      if (typeof (T) == typeof (string))
        hash_func = str_hash;

      return hash_func (this.value);
    }
}