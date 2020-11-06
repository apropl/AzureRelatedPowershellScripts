using System;
using System.Collections.Generic;
using System.Text;

namespace Function_App_Name_NS.Test
{
  public class NullScope : IDisposable
  {
    public static NullScope Instance { get; } = new NullScope();

    private NullScope() { }

    public void Dispose() { }
  }
}
