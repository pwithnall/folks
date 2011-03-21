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

using Tracker.Sparql;
using TrackerTest;
using Folks;
using Gee;

public class UrlDetailsInterfaceTests : Folks.TestCase
{
  private GLib.MainLoop _main_loop;
  private IndividualAggregator _aggregator;
  private TrackerTest.Backend _tracker_backend;
  private string _blog_url;
  private string _website_url;
  private string _urls;
  private bool _found_blog;
  private bool _found_website;

  public UrlDetailsInterfaceTests ()
    {
      base ("UrlDetailsInterfaceTests");

      this._tracker_backend = new TrackerTest.Backend ();
      this._tracker_backend.debug = false;

      this.add_test ("test url details interface",
          this.test_url_details_interface);
    }

  public override void set_up ()
    {
    }

  public override void tear_down ()
    {
    }

  public void test_url_details_interface ()
    {
      this._main_loop = new GLib.MainLoop (null, false);
      Gee.HashMap<string, string> c1 = new Gee.HashMap<string, string> ();
      this._blog_url = "http://blog.example.org";
      this._website_url = "http://www.example.org";
      this._urls = "%s,%s".printf (this._blog_url, this._website_url);

      c1.set (Trf.OntologyDefs.NCO_FULLNAME, "persona #1");
      c1.set (TrackerTest.Backend.URLS, this._urls);
      this._tracker_backend.add_contact (c1);

      this._tracker_backend.set_up ();

      this._found_blog = false;
      this._found_website = false;

      this._test_url_details_interface_async ();

      Timeout.add_seconds (5, () =>
        {
          this._main_loop.quit ();
          assert_not_reached ();
        });

      this._main_loop.run ();

      assert (this._found_blog == true);
      assert (this._found_website == true);

      this._tracker_backend.tear_down ();
    }

  private async void _test_url_details_interface_async ()
    {
      var store = BackendStore.dup ();
      yield store.prepare ();
      this._aggregator = new IndividualAggregator ();
      this._aggregator.individuals_changed.connect
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

  private void _individuals_changed_cb
      (GLib.List<Individual>? added,
       GLib.List<Individual>? removed,
       string? message,
       Persona? actor,
       GroupDetails.ChangeReason reason)
    {
      foreach (Individual i in added)
        {
          string full_name = i.full_name;
          if (full_name != null)
            {
              foreach (var url in i.urls)
                {
                  if (url.value == this._blog_url)
                    {
                      this._found_blog = true;
                    }
                  else if (url.value == this._website_url)
                    {
                      this._found_website = true;
                    }
                }
            }
        }

      assert (removed == null);

      if (this._found_blog &&
          this._found_website)
        this._main_loop.quit ();
    }
}

public int main (string[] args)
{
  Test.init (ref args);

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new UrlDetailsInterfaceTests ().get_suite ());

  Test.run ();

  return 0;
}