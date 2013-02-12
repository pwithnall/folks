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
 * Authors: Raul Gutierrez Segales <raul.gutierrez.segales@collabora.co.uk>
 *
 */

using EdsTest;
using Folks;
using Gee;

public class SetIMAddressesTests : Folks.TestCase
{
  private EdsTest.Backend _eds_backend;
  private IndividualAggregator _aggregator;
  private GLib.MainLoop _main_loop;
  private bool _found_before_update;
  private bool _found_after_update;

  public SetIMAddressesTests ()
    {
      base ("SetIMAddresses");

      this.add_test ("setting im addresses on e-d-s persona",
          this.test_set_im_addresses);
    }

  public override void set_up ()
    {
      this._eds_backend = new EdsTest.Backend ();
      this._eds_backend.set_up ();

      /* We configure eds as the primary store */
      var config_val = "eds:%s".printf (this._eds_backend.address_book_uid);
      Environment.set_variable ("FOLKS_PRIMARY_STORE", config_val, true);
    }

  public override void tear_down ()
    {
      this._eds_backend.tear_down ();
    }

  void test_set_im_addresses ()
    {
      Gee.HashMap<string, Value?> c1 = new Gee.HashMap<string, Value?> ();
      this._main_loop = new GLib.MainLoop (null, false);
      Value? v;

      this._found_before_update = false;
      this._found_after_update = false;

      this._eds_backend.reset ();

      v = Value (typeof (string));
      v.set_string ("bernie h. innocenti");
      c1.set ("full_name", (owned) v);
      this._eds_backend.add_contact (c1);

      this._test_set_im_addresses_async.begin ();

      Timeout.add_seconds (5, () => {
            this._main_loop.quit ();
            assert_not_reached ();
          });

      this._main_loop.run ();

      assert (this._found_before_update);
      assert (this._found_after_update);
    }

  private async void _test_set_im_addresses_async ()
    {
      yield this._eds_backend.commit_contacts_to_addressbook ();

      var store = BackendStore.dup ();
      yield store.prepare ();
      this._aggregator = new IndividualAggregator ();
      this._aggregator.individuals_changed_detailed.connect
          (this._individuals_changed_cb);
      try
        {
          yield this._aggregator.prepare ();
        }
      catch (GLib.Error e)
        {
          GLib.warning ("Error when calling prepare: %s\n", e.message);
        }
    }

  private void _individuals_changed_cb (
       MultiMap<Individual?, Individual?> changes)
    {
      var added = changes.get_values ();

      foreach (Individual i in added)
        {
          assert (i != null);

          var name = (Folks.NameDetails) i;

          if (name.full_name != "bernie h. innocenti")
            continue;

          /* Because we update a linkable property, we'll
             get a new individual because re-linking has to
             happen.
          */
          if (!this._found_before_update)
            {
              this._found_before_update = true;

              foreach (var p in i.personas)
                {
                  var im_addrs = new HashMultiMap<string, ImFieldDetails> (
                      null, null,
                      (Gee.HashDataFunc)
                          AbstractFieldDetails<string>.hash_static,
                      (Gee.EqualDataFunc)
                          AbstractFieldDetails<string>.equal_static);
                  im_addrs.set ("jabber",
                      new ImFieldDetails ("bernie@example.org"));
                  ((ImDetails) p).im_addresses = im_addrs;
                }
            }
          else
            {
              foreach (var proto in i.im_addresses.get_keys ())
                {
                  foreach (var im_fd in i.im_addresses.get (proto))
                    {
                      if (im_fd.equal (
                              new ImFieldDetails ("bernie@example.org")))
                        {
                          this._found_after_update = true;
                          this._main_loop.quit ();
                        }
                    }
                }
            }
        }
    }
}

public int main (string[] args)
{
  Test.init (ref args);

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new SetIMAddressesTests ().get_suite ());

  Test.run ();

  return 0;
}
