namespace Section2;

using Newtonsoft.Json;

using System;

internal static class Program
{
    private static void Main(string[] args)
    {
        string json = JsonConvert.SerializeObject(args);
        Console.WriteLine(json);
    }
}
